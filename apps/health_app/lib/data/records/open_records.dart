import 'dart:async';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:local_store/local_store.dart';
import 'package:path_provider/path_provider.dart';

RecordsDatabase openRecordsDatabase() => RecordsDatabase(
  driftDatabase(
    name: 'orange_health_records',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        // Never silently accept ephemeral storage or unsafe concurrent tabs.
        if (result.chosenImplementation == WasmStorageImplementation.inMemory ||
            result.chosenImplementation ==
                WasmStorageImplementation.unsafeIndexedDb) {
          unawaited(result.resolvedExecutor.executor.close());
          throw StateError('Persistent safe browser storage unavailable');
        }
      },
    ),
  ),
);
