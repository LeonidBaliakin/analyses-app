import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app/health_app.dart';
import 'data/preferences/shared_preferences_repository.dart';
import 'data/records/open_records.dart';
import 'features/records/records.dart';
import 'data/device_access/plugin_device_access.dart';
import 'features/device_access/device_access.dart';
import 'features/settings/settings.dart';
import 'presentation/demo_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferencesAsync();
  final settings = SettingsViewModel(
    repository: SharedPreferencesRepository(preferences),
  );
  await settings.load();
  final catalog = await DemoCatalog.load();
  const introductionKey = 'analyses.device-access-introduction.v1';
  var introductionRequired = true;
  try {
    introductionRequired = await preferences.getBool(introductionKey) != true;
  } on Exception {
    // A failed preference read must not prevent opening the local app.
  }
  final deviceAccess = DeviceAccessViewModel(
    gateway: PluginDeviceAccess(),
    introductionRequired: introductionRequired,
    rememberIntroduction: () => preferences.setBool(introductionKey, true),
  );
  await deviceAccess.recoverAttachments();
  final records = RecordsViewModel(
    repository: openRecordsDatabase(),
    newId: const Uuid().v4,
    clock: DateTime.now,
  );
  await records.load();
  runApp(
    HealthApp(
      settings: settings,
      catalog: catalog,
      deviceAccess: deviceAccess,
      records: records,
    ),
  );
}
