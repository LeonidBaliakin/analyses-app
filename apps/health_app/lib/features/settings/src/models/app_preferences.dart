enum AppLanguage { system, ru, en }

enum AppThemeMode { system, light, dark }

final class AppPreferences {
  const AppPreferences({
    this.language = AppLanguage.system,
    this.themeMode = AppThemeMode.system,
    this.introductionCompleted = false,
  });

  final AppLanguage language;
  final AppThemeMode themeMode;
  final bool introductionCompleted;

  AppPreferences copyWith({
    AppLanguage? language,
    AppThemeMode? themeMode,
    bool? introductionCompleted,
  }) => AppPreferences(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    introductionCompleted: introductionCompleted ?? this.introductionCompleted,
  );
}
