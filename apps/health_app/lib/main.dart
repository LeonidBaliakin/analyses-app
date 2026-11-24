import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app/health_app.dart';
import 'data/preferences/shared_preferences_repository.dart';
import 'data/records/open_records.dart';
import 'features/records/records.dart';
import 'features/documents/documents.dart';
import 'data/documents/documents_http_gateway.dart';
import 'data/documents/export_original.dart';
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
  final deviceGateway = PluginDeviceAccess();
  final deviceAccess = DeviceAccessViewModel(
    gateway: deviceGateway,
    introductionRequired: introductionRequired,
    rememberIntroduction: () => preferences.setBool(introductionKey, true),
  );
  await deviceAccess.recoverAttachments();
  final database = openRecordsDatabase();
  final records = RecordsViewModel(
    repository: database,
    newId: const Uuid().v4,
    clock: DateTime.now,
  );
  await records.load();
  final originals = OriginalsViewModel(
    repository: database,
    profileId: RecordsViewModel.profileId,
    newId: const Uuid().v4,
    clock: DateTime.now,
    device: deviceGateway,
    saveCopy: exportOriginal,
    gatewayFactory: (endpoint, token) =>
        DocumentsHttpGateway(endpoint: endpoint, token: token),
  );
  runApp(
    HealthApp(
      settings: settings,
      catalog: catalog,
      deviceAccess: deviceAccess,
      records: records,
      originals: originals,
    ),
  );
}
