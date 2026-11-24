import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/settings/settings.dart';

import '../support/memory_preferences_repository.dart';

void main() {
  test('restores preferences after recreating the ViewModel', () async {
    final repository = MemoryPreferencesRepository();
    final first = SettingsViewModel(repository: repository);
    await first.load();
    await first.setLanguage(AppLanguage.ru);
    await first.setThemeMode(AppThemeMode.dark);
    first.dispose();

    final second = SettingsViewModel(repository: repository);
    addTearDown(second.dispose);
    await second.load();
    expect(second.preferences.language, AppLanguage.ru);
    expect(second.preferences.themeMode, AppThemeMode.dark);
  });

  test('failed write retains the saved value and allows retry', () async {
    final repository = MemoryPreferencesRepository()..failWrite = true;
    final model = SettingsViewModel(repository: repository);
    addTearDown(model.dispose);
    await model.setThemeMode(AppThemeMode.dark);
    expect(model.error, SettingsError.save);
    expect(model.preferences.themeMode, AppThemeMode.system);
    repository.failWrite = false;
    await model.setThemeMode(AppThemeMode.dark);
    expect(model.error, isNull);
    expect(model.preferences.themeMode, AppThemeMode.dark);
  });

  test('failed read uses defaults and can be retried', () async {
    final repository = MemoryPreferencesRepository()
      ..failRead = true
      ..value = const AppPreferences(language: AppLanguage.en);
    final model = SettingsViewModel(repository: repository);
    addTearDown(model.dispose);
    await model.load();
    expect(model.error, SettingsError.load);
    expect(model.preferences.language, AppLanguage.system);
    repository.failRead = false;
    await model.load();
    expect(model.preferences.language, AppLanguage.en);
    expect(model.error, isNull);
  });

  test(
    'blocks overlapping writes and does not notify after disposal',
    () async {
      final repository = MemoryPreferencesRepository()
        ..writeGate = Completer<void>();
      final model = SettingsViewModel(repository: repository);
      var notifications = 0;
      model.addListener(() => notifications++);
      final pending = model.setLanguage(AppLanguage.ru);
      expect(model.isBusy, isTrue);
      await model.setThemeMode(AppThemeMode.dark);
      expect(repository.writes, 1);
      model.dispose();
      repository.writeGate!.complete();
      await pending;
      expect(notifications, 1);
    },
  );
}
