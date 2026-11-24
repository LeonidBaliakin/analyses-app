import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';

import '../../../platform/device_access.dart';

final class OriginalsViewModel extends ChangeNotifier {
  OriginalsViewModel({
    required this.repository,
    required this.profileId,
    required this.newId,
    required this.clock,
    this.device = const UnavailableDeviceAccess(),
    required this.saveCopy,
    required this.gatewayFactory,
    this._gateway,
    this.processingFactory,
  });
  final OriginalRepository repository;
  final String profileId;
  final String Function() newId;
  final DateTime Function() clock;
  final DeviceAccessGateway device;
  final Future<void> Function(OriginalDocument, Uint8List) saveCopy;
  final DocumentsGateway Function(Uri, String) gatewayFactory;
  DocumentsGateway? _gateway;
  final ProcessingEngine? Function(DocumentsGateway)? processingFactory;
  ProcessingEngine? _processingEngine;
  ProcessingEngine? get processingEngine => _processingEngine;
  bool get connected => _gateway != null;
  bool isCurrentDestination(OriginalDocument original) =>
      _gateway != null && original.cloudDestination == _gateway!.destinationId;
  List<OriginalDocument> originals = const [];
  bool busy = false, _disposed = false;
  String? error, notice;
  final Map<SelectedAttachment, OriginalDocument> _pendingImports = {};
  SelectedAttachment? _retrySelection;
  String _retrySource = 'files';
  bool get canRetryImport => _retrySelection != null;

  bool configure(String endpoint, String token) {
    try {
      connect(gatewayFactory(Uri.parse(endpoint.trim()), token.trim()));
      return true;
    } catch (_) {
      error = 'connection';
      _notify();
      return false;
    }
  }

  void connect(DocumentsGateway gateway) {
    if (busy) {
      gateway.close();
      return;
    }
    _gateway?.close();
    _processingEngine?.close();
    _processingEngine = processingFactory?.call(gateway);
    _gateway = gateway;
    error = null;
    _notify();
  }

  void disconnect() {
    if (busy) return;
    _gateway?.close();
    _gateway = null;
    _processingEngine?.close();
    _processingEngine = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notice = null;
    _notify();
    try {
      await action();
    } on OriginalFailure catch (e) {
      error = e.code;
    } on DeviceAccessException catch (e) {
      error = e.issue == AccessIssue.cancelled ? 'cancelled' : 'pick';
    } catch (_) {
      error = 'failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() => _run(() async {
    originals = await repository.listOriginals(profileId);
  });

  Future<void> pick(AttachmentSource source) => _run(() async {
    final selected = await device.pick(source);
    if (selected == null) return;
    await _import(selected, source.name);
  });

  Future<void> importSelected(SelectedAttachment selected, String source) =>
      _run(() => _import(selected, source));
  Future<void> retryImport() => _run(() async {
    if (_retrySelection != null) await _import(_retrySelection!, _retrySource);
  });
  Future<void> _import(SelectedAttachment selected, String source) async {
    _retrySelection = selected;
    _retrySource = source;
    if (selected.size < 1 || selected.size > maxOriginalBytes) {
      throw const OriginalFailure('too_large');
    }
    final Uint8List bytes;
    if (selected.openRead case final open?) {
      final buffer = BytesBuilder();
      await for (final chunk in open()) {
        if (buffer.length + chunk.length > maxOriginalBytes) {
          throw const OriginalFailure('too_large');
        }
        buffer.add(chunk);
      }
      bytes = buffer.takeBytes();
    } else {
      bytes = await selected.readBytes();
    }
    if (bytes.length != selected.size || bytes.length > maxOriginalBytes) {
      throw const OriginalFailure('integrity');
    }
    final original = _pendingImports.putIfAbsent(
      selected,
      () => OriginalDocument(
        documentId: newId(),
        originalId: newId(),
        profileId: profileId,
        fileName: selected.name,
        mime: originalMime(bytes),
        size: bytes.length,
        sha256: originalSha256(bytes),
        importedAt: clock().toUtc(),
        importSource: source,
      ),
    );
    original.verify(bytes);
    await repository.importOriginal(original, bytes);
    originals = await repository.listOriginals(profileId);
    _retrySelection = null;
    _pendingImports.remove(selected);
    notice = 'local';
  }

  Future<void> upload(OriginalDocument original) => _run(() async {
    final gateway = _gateway;
    if (gateway == null) throw const OriginalFailure('connection');
    final bytes = await repository.readOriginal(profileId, original.originalId);
    original.verify(bytes);
    await repository.setOriginalCloudState(
      profileId,
      original.originalId,
      OriginalCloudState.pending,
      destinationId: gateway.destinationId,
    );
    originals = await repository.listOriginals(profileId);
    _notify();
    await gateway.upload(original, bytes);
    await repository.setOriginalCloudState(
      profileId,
      original.originalId,
      OriginalCloudState.ready,
      destinationId: gateway.destinationId,
    );
    originals = await repository.listOriginals(profileId);
    notice = 'uploaded';
  });

  Future<void> verifyCloud(OriginalDocument original) => _run(() async {
    if (!isCurrentDestination(original)) {
      throw const OriginalFailure('connection');
    }
    original.verify(await _gateway!.download(original));
    notice = 'verified';
  });

  Future<void> export(OriginalDocument original) => _run(() async {
    final bytes = await repository.readOriginal(profileId, original.originalId);
    original.verify(bytes);
    await saveCopy(original, bytes);
  });
  @override
  void dispose() {
    _disposed = true;
    _gateway?.close();
    _processingEngine?.close();
    super.dispose();
  }
}
