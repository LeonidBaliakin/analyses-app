import 'app_preferences.dart';

/// Device preferences only. Medical records need transactional storage.
abstract interface class PreferencesRepository {
  Future<AppPreferences> read();
  Future<void> write(AppPreferences preferences);
}
