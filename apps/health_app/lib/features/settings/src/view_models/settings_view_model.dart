import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import '../models/preferences_repository.dart';

enum SettingsError { load, save }

final class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required this._repository});

  final PreferencesRepository _repository;
  AppPreferences _preferences = const AppPreferences();
  AppPreferences get preferences => _preferences;
  bool _isBusy = false;
  bool get isBusy => _isBusy;
  SettingsError? _error;
  SettingsError? get error => _error;
  bool _disposed = false;

  Future<void> load() async {
    if (_isBusy || _disposed) return;
    _isBusy = true;
    _notify();
    try {
      _preferences = await _repository.read();
      _error = null;
    } on Exception {
      _error = SettingsError.load;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  Future<void> setLanguage(AppLanguage language) =>
      _save(_preferences.copyWith(language: language));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _save(_preferences.copyWith(themeMode: mode));

  Future<bool> completeIntroduction() async {
    if (_preferences.introductionCompleted) return true;
    await _save(_preferences.copyWith(introductionCompleted: true));
    return _preferences.introductionCompleted;
  }

  Future<void> _save(AppPreferences next) async {
    if (_isBusy || _disposed) return;
    _isBusy = true;
    _notify();
    try {
      await _repository.write(next);
      _preferences = next;
      _error = null;
    } on Exception {
      _error = SettingsError.save;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
