import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app/health_app.dart';
import 'data/preferences/shared_preferences_repository.dart';
import 'data/records/open_records.dart';
import 'features/records/records.dart';
import 'features/documents/documents.dart';
import 'data/documents/documents_http_gateway.dart';
import 'data/documents/export_original.dart';
import 'data/processing/local_engine.dart';
import 'data/processing/remote_engine.dart';
import 'features/processing/processing.dart';
import 'features/reports/reports.dart';
import 'features/sync/sync.dart';
import 'data/sync/http_sync_gateway.dart';
import 'features/account/account.dart';
import 'data/account/http_account_gateway.dart';
import 'data/account/session_storage.dart';

import 'package:flutter/foundation.dart';

import 'data/reports/export_report.dart';
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
    processingFactory: (gateway) => gateway is DocumentsHttpGateway
        ? RemoteProcessingEngine(
            endpoint: gateway.endpoint,
            token: gateway.token,
            profileId: RecordsViewModel.profileId,
            accountOwnerId: gateway.accountOwnerId,
          )
        : null,
  );
  final processing = ProcessingViewModel(
    repository: database,
    originals: database,
    local: createLocalProcessingEngine(),
    server: () => originals.processingEngine,
    serverOriginalReady: (o) =>
        originals.isCurrentDestination(o) &&
        originals.originals.any(
          (current) =>
              current.originalId == o.originalId &&
              current.cloudState.name == 'ready',
        ),
    newId: const Uuid().v4,
    onConfirmed: records.load,
  );
  final reports = ReportsViewModel(
    records: records,
    clock: DateTime.now,
    export: exportReport,
    canExport: canExportReportFile,
    copy: (text) => Clipboard.setData(ClipboardData(text: text)),
  );
  final sync = SyncViewModel(
    store: database,
    profileId: RecordsViewModel.profileId,
    newId: const Uuid().v4,
    clock: DateTime.now,
    changes: records,
    gatewayFactory: (uri, token) => HttpSyncGateway(
      endpoint: uri,
      token: token,
      profileId: RecordsViewModel.profileId,
    ),
    onChanged: records.load,
  );
  await sync.refresh();
  const configuredApi = String.fromEnvironment('CLOUD_API_URL');
  final endpoint = Uri.parse(
    configuredApi.isNotEmpty
        ? configuredApi
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:18088/'
        : kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.host}:18088/'
        : 'http://127.0.0.1:18088/',
  );
  final account = AccountViewModel(
    endpoint: endpoint,
    gatewayFactory: (uri, token) => HttpAccountGateway(uri, token: token),
    storage: const DeviceSessionStorage(),
    onDisconnect: () {
      sync.disconnect();
      originals.disconnect();
    },
    onConnect: (session) async {
      final connected = await sync.connect(endpoint.toString(), session.token);
      if (!connected) return false;
      originals.connect(
        DocumentsHttpGateway(
          endpoint: endpoint,
          token: session.token,
          accountOwnerId: session.ownerId,
        ),
      );
      return true;
    },
  );
  runApp(
    HealthApp(
      settings: settings,
      catalog: catalog,
      deviceAccess: deviceAccess,
      records: records,
      originals: originals,
      processing: processing,
      reports: reports,
      sync: sync,
      account: account,
    ),
  );
  // Restoring a session must not delay or block opening local medical records.
  unawaited(account.restore());
}
