import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:document_domain/document_domain.dart';
import 'package:record_sync/record_sync.dart';

class SyncViewModel extends ChangeNotifier {
  SyncViewModel({
    required this.store,
    required this.profileId,
    required this.newId,
    required this.clock,
    required this.gatewayFactory,
    required this.onChanged,
    this.changes,
  }) {
    changes?.addListener(_localChanged);
  }
  final Listenable? changes;
  void _localChanged() {
    unawaited(refresh());
  }

  final SyncStore store;
  final String profileId;
  final String Function() newId;
  final DateTime Function() clock;
  final SyncGateway Function(Uri, String) gatewayFactory;
  final Future<void> Function() onChanged;
  SyncGateway? _gateway;
  Timer? _timer;
  bool busy = false, _disposed = false;
  int _generation = 0;
  SyncScope? scope;
  List<SyncConflict> conflicts = const [];
  int pending = 0;
  String? error;
  bool get connected => _gateway != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    try {
      scope = await store.syncScope(profileId);
      pending = await store.pendingSyncCount(profileId);
      conflicts = await store.syncConflicts(profileId);
    } catch (_) {
      error = 'storage';
    }
    _notify();
  }

  Future<bool> connect(String endpoint, String token) async {
    if (busy) return false;
    busy = true;
    error = null;
    _notify();
    SyncGateway? incoming;
    try {
      final uri = Uri.parse(endpoint.trim()).replace(path: '/');
      incoming = gatewayFactory(uri, token.trim());
      final identity = await incoming.identity();
      if (_disposed) throw const SyncFailure('cancelled');
      await store.bindSync(
        profileId,
        originalSha256(
          utf8.encode('${uri.toString()}\n${identity.ownerId}\n$profileId'),
        ),
        newId(),
        identity,
      );
      _gateway?.close();
      _gateway = incoming;
      incoming = null;
      _generation++;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(synchronize());
      });
      busy = false;
      await synchronize(force: true);
      return true;
    } catch (e) {
      error = e is SyncFailure ? e.code : 'connection';
      return false;
    } finally {
      incoming?.close();
      busy = false;
      await refresh();
      _notify();
    }
  }

  Future<void> synchronize({bool force = false}) async {
    final gateway = _gateway;
    if (busy || gateway == null || _disposed) return;
    busy = true;
    error = null;
    final generation = _generation;
    _notify();
    try {
      await SyncRunner(store, gateway, profileId, clock).run(
        force: force,
        cancelled: () => _disposed || generation != _generation,
      );
      if (!_disposed && generation == _generation) await onChanged();
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = e is SyncFailure ? e.code : 'network';
      }
    } finally {
      busy = false;
      if (!_disposed) {
        await refresh();
        _notify();
      }
    }
  }

  Future<void> resolve(SyncConflict conflict, bool keepLocal) async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      await store.resolveSyncConflict(
        profileId,
        conflict.local.record.id,
        keepLocal: keepLocal,
        operationId: newId(),
        localRevision: conflict.local.revision,
        remoteVersion: conflict.remote.version,
      );
      await onChanged();
    } catch (_) {
      error = 'conflict_changed';
    } finally {
      busy = false;
      await refresh();
      _notify();
    }
  }

  void disconnect() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _gateway?.close();
    _gateway = null;
    _notify();
  }

  @override
  void dispose() {
    changes?.removeListener(_localChanged);
    _disposed = true;
    disconnect();
    super.dispose();
  }
}
