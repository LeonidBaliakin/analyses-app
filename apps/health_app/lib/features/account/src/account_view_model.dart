import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'account_models.dart';

enum AccountMode { login, register, recover }

class AccountViewModel extends ChangeNotifier {
  AccountViewModel({
    required this.endpoint,
    required this.gatewayFactory,
    required this.storage,
    required this.onConnect,
    required this.onDisconnect,
  });
  final Uri endpoint;
  final AccountGateway Function(Uri, String) gatewayFactory;
  final SessionStorage storage;
  final Future<bool> Function(AccountSession) onConnect;
  final VoidCallback onDisconnect;
  AccountGateway? _gateway;
  Timer? _timer;
  int _generation = 0;
  bool busy = false,
      connecting = false,
      cloudConnected = false,
      _disposed = false;
  AccountMode mode = AccountMode.login;
  AccountSession? session;
  List<AccountDevice> devices = const [];
  AccountCloudStatus? cloud;
  String? cloudError;
  String? challengeId, error, message;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    message = null;
    _notify();
    try {
      await work();
    } catch (e) {
      error = e is AccountFailure ? e.code : 'network';
    } finally {
      busy = false;
      _notify();
    }
  }

  void selectMode(AccountMode next) {
    if (busy) return;
    mode = next;
    challengeId = null;
    error = null;
    message = null;
    _notify();
  }

  AccountGateway get _api =>
      _gateway ??= gatewayFactory(endpoint, session?.token ?? '');
  Future<void> restore() => _run(() async {
    try {
      final stored = await storage.read();
      if (stored != null) {
        final j = jsonDecode(stored) as Map<String, dynamic>;
        if (j['endpoint'] != endpoint.toString()) {
          throw const AccountFailure('endpoint_changed');
        }
        _gateway = gatewayFactory(endpoint, j['token'] as String);
      } else if (!kIsWeb) {
        return;
      }
      await _accept(await _api.current());
    } on AccountFailure catch (e) {
      if (e.code == 'unauthorized') {
        await storage.clear();
        _gateway?.close();
        _gateway = null;
        return;
      }
      rethrow;
    }
  });
  Future<void> requestCode(String email) => _run(() async {
    challengeId = await _api.challenge(email, mode == AccountMode.recover);
    message = 'code_sent';
  });
  Future<void> submit(
    String email,
    String password,
    String label,
    String code,
  ) => _run(() async {
    if (mode == AccountMode.recover) {
      await _api.recover(challengeId!, code, password);
      mode = AccountMode.login;
      challengeId = null;
      message = 'recovered';
      try {
        await storage.clear();
      } catch (_) {
        error = 'secure_storage';
      }
      return;
    }
    final next = mode == AccountMode.login
        ? await _api.login(email, password, label)
        : await _api.register(challengeId!, code, password, label);
    await _accept(next);
  });
  Future<void> _accept(AccountSession next) async {
    if (_disposed) return;
    final generation = ++_generation;
    session = next;
    cloud = null;
    cloudError = null;
    challengeId = null;
    try {
      await storage.write(
        jsonEncode({'endpoint': endpoint.toString(), 'token': next.token}),
      );
    } catch (_) {
      error = 'secure_storage';
    }
    if (_disposed || generation != _generation) return;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(validate()),
    );
    final currentDevices = await _api.devices();
    if (!_disposed && generation == _generation) devices = currentDevices;
    if (!_disposed && generation == _generation) await _loadCloud();
  }

  Future<void> _loadCloud() async {
    final generation = _generation;
    try {
      final value = await _api.cloudStatus();
      if (!_disposed && generation == _generation) {
        cloud = value;
        cloudError = null;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) cloudError = 'unavailable';
    }
  }

  Future<void> refreshCloud() => _run(_loadCloud);

  Future<void> connectCloud() => _run(() async {
    final current = session;
    if (current == null) return;
    connecting = true;
    try {
      cloudConnected = await onConnect(current);
      if (!cloudConnected) error = 'binding';
      await _loadCloud();
    } finally {
      connecting = false;
    }
  });
  Future<void> validate() async {
    if (busy || session == null || _disposed) return;
    final generation = _generation;
    try {
      final current = await _api.current();
      if (_disposed || generation != _generation) return;
      if (current.ownerId != session?.ownerId ||
          current.sessionId != session?.sessionId) {
        await _forget();
        error = 'session_expired';
        _notify();
      }
    } on AccountFailure catch (e) {
      if (_disposed || generation != _generation) return;
      if (e.code == 'unauthorized') {
        await _forget();
        error = 'session_expired';
        _notify();
      }
    } catch (_) {
      // Connectivity and secure-storage failures do not erase local records.
    }
  }

  Future<void> loadDevices() => _run(() async {
    devices = await _api.devices();
  });
  Future<void> revoke(AccountDevice device) => _run(() async {
    await _api.revoke(device.id);
    if (device.current) {
      await _forget();
    } else {
      devices = await _api.devices();
    }
  });
  Future<void> logout({bool all = false}) => _run(() async {
    // A failed server revocation stays visible and can be retried; local data is never deleted.
    await _api.logout(all: all);
    await _forget();
  });
  Future<void> _forget() async {
    _generation++;
    onDisconnect();
    cloudConnected = false;
    session = null;
    cloud = null;
    cloudError = null;
    devices = const [];
    _timer?.cancel();
    _gateway?.close();
    _gateway = null;
    try {
      await storage.clear();
    } catch (_) {
      error = 'secure_storage';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _gateway?.close();
    super.dispose();
  }
}
