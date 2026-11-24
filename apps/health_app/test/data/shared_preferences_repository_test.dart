import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/preferences/shared_preferences_repository.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePreferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('round trips both choices through one persistent value', () async {
    final storage = FakePreferences();
    await SharedPreferencesRepository(storage).write(
      const AppPreferences(
        language: AppLanguage.ru,
        themeMode: AppThemeMode.dark,
        introductionCompleted: true,
      ),
    );
    final result = await SharedPreferencesRepository(storage).read();
    expect(result.language, AppLanguage.ru);
    expect(result.themeMode, AppThemeMode.dark);
    expect(result.introductionCompleted, isTrue);
    expect(storage.values.keys, [SharedPreferencesRepository.storageKey]);
  });

  test('missing preferences follow the system', () async {
    final result = await SharedPreferencesRepository(FakePreferences()).read();
    expect(result.language, AppLanguage.system);
    expect(result.themeMode, AppThemeMode.system);
    expect(result.introductionCompleted, isFalse);
  });

  test('existing appearance preferences start the introduction once', () async {
    final storage = FakePreferences();
    storage.values[SharedPreferencesRepository.storageKey] =
        '{"language":"ru","themeMode":"dark"}';
    final result = await SharedPreferencesRepository(storage).read();
    expect(result.language, AppLanguage.ru);
    expect(result.themeMode, AppThemeMode.dark);
    expect(result.introductionCompleted, isFalse);
  });

  test(
    'malformed or unsupported stored values report a recoverable error',
    () async {
      final storage = FakePreferences();
      final repository = SharedPreferencesRepository(storage);
      for (final value in [
        '{',
        '[]',
        '{}',
        '{"language":"fr","themeMode":"dark"}',
        '{"language":"ru","themeMode":null}',
        '{"language":"ru","themeMode":"dark","introductionCompleted":"true"}',
      ]) {
        storage.values[SharedPreferencesRepository.storageKey] = value;
        await expectLater(repository.read(), throwsFormatException);
      }
    },
  );
}
