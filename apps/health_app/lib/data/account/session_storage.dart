import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/account/account.dart';

/// Browser sessions use the API's HttpOnly cookie. No bearer in web storage.
class DeviceSessionStorage implements SessionStorage {
  const DeviceSessionStorage();
  static const _key = 'analyses.account-session.v1';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'analyses_account_session',
      resetOnError: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  @override
  Future<String?> read() async {
    if (kIsWeb) return null;
    try {
      return await _secure.read(key: _key);
    } catch (_) {
      throw const AccountFailure('secure_storage');
    }
  }

  @override
  Future<void> write(String value) async {
    if (!kIsWeb) await _secure.write(key: _key, value: value);
  }

  @override
  Future<void> clear() async {
    if (!kIsWeb) await _secure.delete(key: _key);
  }
}
