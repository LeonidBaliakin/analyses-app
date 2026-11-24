import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/settings.dart';

final class SharedPreferencesRepository implements PreferencesRepository {
  SharedPreferencesRepository(this._preferences);

  static const storageKey = 'analyses.preferences.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<AppPreferences> read() async {
    final value = await _preferences.getString(storageKey);
    if (value == null) return const AppPreferences();
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic> ||
        !AppLanguage.values.any((item) => item.name == decoded['language']) ||
        !AppThemeMode.values.any((item) => item.name == decoded['themeMode']) ||
        (decoded.containsKey('introductionCompleted') &&
            decoded['introductionCompleted'] is! bool)) {
      throw const FormatException('Invalid preferences');
    }
    return AppPreferences(
      language: AppLanguage.values.byName(decoded['language'] as String),
      themeMode: AppThemeMode.values.byName(decoded['themeMode'] as String),
      introductionCompleted: decoded['introductionCompleted'] as bool? ?? false,
    );
  }

  @override
  Future<void> write(AppPreferences preferences) => _preferences.setString(
    storageKey,
    jsonEncode({
      'language': preferences.language.name,
      'themeMode': preferences.themeMode.name,
      'introductionCompleted': preferences.introductionCompleted,
    }),
  );
}
