// Debug-only visual preview. Uses synthetic data and in-memory preferences;
// it does not open the user's records, accounts or platform permissions.
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:health_app/app/health_app.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/presentation/demo_catalog.dart';

import '../test/support/memory_preferences_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  enableFlutterDriverExtension();
  final repository = MemoryPreferencesRepository()
    ..value = const AppPreferences(
      language: AppLanguage.ru,
      introductionCompleted: true,
    );
  final settings = SettingsViewModel(repository: repository);
  await settings.load();
  runApp(
    HealthApp(
      settings: settings,
      catalog: await DemoCatalog.load(),
      initialLocation: '/history',
    ),
  );
}
