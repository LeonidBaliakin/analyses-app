// Synthetic real-browser probe. Compile outside the production web bundle.
import 'dart:async';
import 'dart:js_interop';

import 'package:drift/wasm.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:web/web.dart';

@JS('commitProbe')
external set commitProbe(JSFunction function);

void report(String text) {
  document.querySelector('#result')!.textContent = text;
}

void check(bool value) {
  if (!value) throw StateError('Synthetic browser assertion failed');
}

LabResult sample(String raw) => LabResult(
  id: 'result',
  profileId: 'profile',
  name: 'Synthetic browser test',
  value: SourceValue(raw, ResultValueKind.comparison),
  date: CalendarDate(2026, 11, 24),
  category: AnalysisCategory.blood,
  laboratory: 'Synthetic lab',
  method: 'Synthetic method',
);
RecordMutation command(String op, HealthRecord record, int revision) =>
    RecordMutation(operationId: op, record: record, expectedRevision: revision);

Future<void> main() async {
  try {
    final parameters = Uri.base.queryParameters;
    final run = parameters['run']!;
    check(RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(run));
    final result = await WasmDatabase.open(
      databaseName: 'analyses_synthetic_$run',
      sqlite3Uri: Uri.parse('/sqlite3.wasm'),
      driftWorkerUri: Uri.parse('/drift_worker.js'),
    );
    check(
      result.chosenImplementation != WasmStorageImplementation.inMemory &&
          result.chosenImplementation !=
              WasmStorageImplementation.unsafeIndexedDb,
    );
    final db = RecordsDatabase(result.resolvedExecutor);
    final phase = parameters['phase'];
    if (phase == 'seed') {
      await db.commit(
        command(
          'profile-op',
          const MedicalProfile(
            id: 'profile',
            name: 'Synthetic browser profile',
          ),
          0,
        ),
      );
      final mutation = command('result-op', sample('< 0,0100'), 0);
      check(await db.commit(mutation) == 1);
      check(await db.commit(mutation) == 1);
      await db.close();
      report('PASS seed ${result.chosenImplementation.name}');
    } else if (phase == 'hold') {
      final base = (await db.read('profile'))
          .singleWhere((e) => e.record.id == 'result');
      check(base.revision == 1);
      commitProbe = (() {
        unawaited(() async {
          try {
            await db.commit(
              command('stale-op', sample('< 0,9999'), base.revision),
            );
            report('FAIL stale overwrite');
          } on RecordConflict {
            check((await db.history('profile', 'result')).length == 2);
            await db.close();
            report('PASS conflict preserved both revisions');
          } catch (error) {
            report('FAIL $error');
          }
        }());
      }).toJS;
      document.querySelector('#commit')!.removeAttribute('hidden');
      report('READY stale base=1');
    } else if (phase == 'edit') {
      check(await db.commit(command('edit-op', sample('< 0,0200'), 1)) == 2);
      await db.close();
      report('PASS second tab edit revision=2');
    } else if (phase == 'verify') {
      final r = (await db.read('profile'))
          .singleWhere((e) => e.record.id == 'result');
      check(r.revision == 2 && (r.record as LabResult).value.raw == '< 0,0200');
      check((await db.history('profile', 'result')).length == 2);
      check((await db.customSelect('SELECT * FROM outbox').get()).length == 3);
      await db.close();
      report('PASS reopened raw=< 0,0200 history=2 outbox=3');
    } else {
      throw StateError('Unknown phase');
    }
  } catch (error) {
    report('FAIL $error');
  }
}
