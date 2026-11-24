// Synthetic, two-device integration against a Compose deployment via Documents.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:health_app/data/sync/http_sync_gateway.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:uuid/uuid.dart';

class FaultGateway implements SyncGateway {
  FaultGateway(this.inner);
  final SyncGateway inner;
  bool offline = false, lose = false;
  int calls = 0;
  void check() {
    calls++;
    if (offline) throw const SyncFailure('network', retryable: true);
  }

  @override
  Future<SyncIdentity> identity() => inner.identity();
  @override
  Future<SyncChangePage> pull(int c, String e) {
    check();
    return inner.pull(c, e);
  }

  @override
  Future<SyncReply> push(SyncCommand c, String e) async {
    check();
    final reply = await inner.push(c, e);
    if (lose && reply.applied) {
      lose = false;
      throw const SyncFailure('network', retryable: true);
    }
    return reply;
  }

  @override
  void close() => inner.close();
}

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main(List<String> args) async {
  final deployment = Directory(
    args.isEmpty ? '../../.runtime/server-check' : args.first,
  ).absolute;
  final env = {
    for (final l in await File('${deployment.path}/.env').readAsLines())
      l.split('=').first: l.substring(l.indexOf('=') + 1),
  };
  final secrets = jsonDecode(
    await File('${deployment.path}/.secrets/bootstrap.json').readAsString(),
  ) as Map;
  final config =
      (jsonDecode(
            await File('${deployment.path}/.secrets/identities.json')
                .readAsString(),
          ) as List).first
          as Map;
  final profile = config['profileId'] as String;
  final endpoint = Uri.parse('http://127.0.0.1:${env['API_PORT']}/');
  final aGateway = FaultGateway(
    HttpSyncGateway(
      endpoint: endpoint,
      token: secrets['client_token'] as String,
      profileId: profile,
    ),
  );
  final bGateway = HttpSyncGateway(
    endpoint: endpoint,
    token: secrets['client_token'] as String,
    profileId: profile,
  );
  final temp = await Directory.systemTemp.createTemp('analyses-sync-smoke-');
  final file = File('${temp.path}/a.sqlite');
  var a = RecordsDatabase(NativeDatabase(file));
  final b = RecordsDatabase(NativeDatabase(File('${temp.path}/b.sqlite')));
  final now = DateTime.utc(2026, 11, 25), id = 'smoke-${const Uuid().v4()}';
  LabResult lab(String value) => LabResult(
    id: id,
    profileId: profile,
    name: 'SYNTHETIC synchronization probe',
    date: CalendarDate(2026, 11, 25),
    value: SourceValue(value, ResultValueKind.numeric),
    category: AnalysisCategory.blood,
    unit: 'unknown',
  );
  Future<void> save(
    RecordsDatabase db,
    HealthRecord record, {
    bool delete = false,
  }) async {
    final history = await db.history(profile, record.id);
    await db.commit(
      RecordMutation(
        operationId: const Uuid().v4(),
        record: record,
        expectedRevision: history.firstOrNull?.revision ?? 0,
        delete: delete,
      ),
    );
  }

  Future<void> run(
    RecordsDatabase db,
    SyncGateway gateway, {
    bool force = true,
  }) => SyncRunner(db, gateway, profile, () => now).run(force: force);
  Future<LabResult> read(RecordsDatabase db) async =>
      (await db.read(profile))
          .map((e) => e.record)
          .whereType<LabResult>()
          .singleWhere((r) => r.id == id);
  try {
    final identity = await aGateway.identity();
    await a.bindSync(
      profile,
      'synthetic-deployment',
      const Uuid().v4(),
      identity,
    );
    await b.bindSync(
      profile,
      'synthetic-deployment',
      const Uuid().v4(),
      identity,
    );
    await run(a, aGateway);
    if ((await a.read(profile))
        .where((e) => e.record is MedicalProfile)
        .isEmpty) {
      await save(
        a,
        MedicalProfile(id: profile, name: 'SYNTHETIC sync profile'),
      );
    }
    await save(a, lab('0,0100'));
    await run(a, aGateway);
    await run(b, bGateway);
    check((await read(b)).value.raw == '0,0100', 'initial pull');
    check(await b.pendingSyncCount(profile) == 0, 'no echo');
    await save(a, lab('0,0200'));
    await save(b, lab('0,0300'));
    aGateway.offline = true;
    try {
      await run(a, aGateway);
      throw StateError('offline expected');
    } on SyncFailure {
      /* Expected injected transport failure. */
    }
    await a.close();
    a = RecordsDatabase(NativeDatabase(file));
    final before = aGateway.calls;
    await run(a, aGateway, force: false);
    check(aGateway.calls == before, 'persisted backoff');
    aGateway.offline = false;
    aGateway.lose = true;
    try {
      await run(a, aGateway);
      throw StateError('lost response expected');
    } on SyncFailure {
      /* Expected injected transport failure. */
    }
    await run(a, aGateway);
    check(
      await a.pendingSyncCount(profile) == 0,
      'lost acknowledgement recovery',
    );
    await run(b, bGateway);
    final conflict = (await b.syncConflicts(profile))
        .singleWhere((c) => c.local.record.id == id);
    check(
      (conflict.local.record as LabResult).value.raw == '0,0300' &&
          (conflict.remote.record as LabResult).value.raw == '0,0200',
      'both conflict versions',
    );
    await b.resolveSyncConflict(
      profile,
      id,
      keepLocal: true,
      operationId: const Uuid().v4(),
      localRevision: conflict.local.revision,
      remoteVersion: conflict.remote.version,
    );
    await run(b, bGateway);
    await run(a, aGateway);
    check((await read(a)).value.raw == '0,0300', 'explicit resolution');
    await save(b, lab('0,0400'));
    await save(a, await read(a), delete: true);
    await run(a, aGateway);
    await run(b, bGateway);
    final deletion = (await b.syncConflicts(profile))
        .singleWhere((c) => c.local.record.id == id);
    check(deletion.remote.deleted, 'remote tombstone');
    await b.resolveSyncConflict(
      profile,
      id,
      keepLocal: false,
      operationId: const Uuid().v4(),
      localRevision: deletion.local.revision,
      remoteVersion: deletion.remote.version,
    );
    await run(b, bGateway);
    check((await b.history(profile, id)).first.deleted, 'deleted with history');
    var cursor = 0, revisions = 0;
    for (var page = 0; page < 50; page++) {
      final changes = await bGateway.pull(cursor, identity.epoch);
      revisions += changes.records.where((r) => r.record.id == id).length;
      cursor = changes.cursor;
      if (!changes.more) break;
      check(page < 49, 'probe pagination limit');
    }
    check(revisions == 4, 'no duplicated server revisions');
    final course = MedicationCourse(
      id: 'course-$id',
      profileId: profile,
      name: 'SYNTHETIC course',
      start: CalendarDate(2026, 10, 1),
      end: CalendarDate(2026, 12, 1),
    );
    await save(a, course);
    await save(
      a,
      HomeMeasurement(
        id: 'measure-$id',
        profileId: profile,
        name: 'SYNTHETIC measurement',
        date: CalendarDate(2026, 11, 24),
        value: const SourceValue('5,00', ResultValueKind.numeric),
        unit: 'unknown',
        minuteOfDay: 30,
        utcOffsetMinutes: 180,
      ),
    );
    await run(a, aGateway);
    await run(b, bGateway);
    final period = ReportPeriod(
      CalendarDate(2026, 11, 20),
      CalendarDate(2026, 11, 25),
    );
    final ra = HealthReport.build(await a.read(profile), profile, period),
        rb = HealthReport.build(await b.read(profile), profile, period);
    String snapshot(HealthReport r) => jsonEncode({
      'period': [r.period.start.toString(), r.period.end.toString()],
      'profile': r.profile == null ? null : encodeRecord(r.profile!),
      'results': r.results.map(encodeRecord).toList(),
      'courses': r.medications.map(encodeRecord).toList(),
      'measurements': r.measurements.map(encodeRecord).toList(),
    });
    check(snapshot(ra) == snapshot(rb), 'same report on both devices');
    check(ra.medications.any((r) => r.id == course.id), 'overlapping course');
    check(
      !ra.results.any((r) => r.id == id),
      'deleted result excluded from report',
    );
    stdout.writeln(
      'Two SQLite devices via Documents/Compose: offline restart, durable retry, lost ACK, both conflict choices, tombstone and identical period reports verified.',
    );
  } finally {
    aGateway.close();
    bGateway.close();
    await a.close();
    await b.close();
    await temp.delete(recursive: true);
  }
}
