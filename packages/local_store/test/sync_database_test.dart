import 'dart:io';

import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:test/test.dart';

class Cloud implements SyncGateway {
  final current = <String, RemoteRecord>{}, operations = <String, SyncReply>{};
  final changes = <RemoteRecord>[];
  bool offline = false, lose = false;
  int calls = 0;
  @override
  Future<SyncIdentity> identity() async =>
      const SyncIdentity('owner', 'p', 'epoch', true);
  @override
  Future<SyncChangePage> pull(int cursor, String epoch) async {
    calls++;
    if (offline) throw const SyncFailure('network', retryable: true);
    return SyncChangePage(
      'epoch',
      changes.length,
      false,
      changes.skip(cursor).toList(),
    );
  }

  @override
  Future<SyncReply> push(SyncCommand c, String epoch) async {
    calls++;
    if (offline) throw const SyncFailure('network', retryable: true);
    final id = '${c.deviceId}:${c.operationId}';
    if (operations.containsKey(id)) return operations[id]!;
    final old = current[c.record.id];
    if ((old?.version ?? 0) != c.baseVersion) {
      return operations[id] = SyncReply(false, old!);
    }
    final r = RemoteRecord(
      payload: c.payload,
      version: c.baseVersion + 1,
      deleted: c.deleted,
      sequence: changes.length + 1,
      deviceId: c.deviceId,
      operationId: c.operationId,
    );
    current[c.record.id] = r;
    changes.add(r);
    final reply = operations[id] = SyncReply(true, r);
    if (lose) {
      lose = false;
      throw const SyncFailure('network', retryable: true);
    }
    return reply;
  }

  @override
  void close() {}
}

void main() {
  late Directory temp;
  late RecordsDatabase a, b;
  late Cloud cloud;
  final now = DateTime.utc(2026, 11, 25);
  var op = 0;
  LabResult lab(String value) => LabResult(
    id: 'r',
    profileId: 'p',
    name: 'Synthetic',
    date: CalendarDate(2026, 11, 24),
    value: SourceValue(value, ResultValueKind.numeric),
    category: AnalysisCategory.blood,
    unit: 'mmol/L',
  );
  Future<void> save(
    RecordsDatabase db,
    HealthRecord r, {
    bool delete = false,
  }) async {
    final h = await db.history('p', r.id);
    await db.commit(
      RecordMutation(
        operationId: 'op-${op++}',
        record: r,
        expectedRevision: h.firstOrNull?.revision ?? 0,
        delete: delete,
      ),
    );
  }

  Future<void> run(RecordsDatabase db, {bool force = true}) =>
      SyncRunner(db, cloud, 'p', () => now).run(force: force);
  setUp(() async {
    op = 0;
    temp = Directory.systemTemp.createTempSync('record-sync-');
    a = RecordsDatabase(
      NativeDatabase(File('${temp.path}/a.sqlite')),
      clock: () => now,
    );
    b = RecordsDatabase(
      NativeDatabase(File('${temp.path}/b.sqlite')),
      clock: () => now,
    );
    cloud = Cloud();
    await a.bindSync('p', 'destination', 'device-a', await cloud.identity());
    await b.bindSync('p', 'destination', 'device-b', await cloud.identity());
    await save(a, const MedicalProfile(id: 'p', name: 'Synthetic'));
    await save(a, lab('5,00'));
  });
  tearDown(() async {
    await a.close();
    await b.close();
    temp.deleteSync(recursive: true);
  });
  test('offline/restart/backoff and lost acknowledgement preserve a single durable operation', () async {
    cloud.offline = true;
    await expectLater(run(a), throwsA(isA<SyncFailure>()));
    expect(await a.pendingSyncCount('p'), 2);
    expect(
      (await a.syncScope('p'))!.retryAt,
      now.add(const Duration(seconds: 2)),
    );
    await a.close();
    a = RecordsDatabase(
      NativeDatabase(File('${temp.path}/a.sqlite')),
      clock: () => now,
    );
    final count = cloud.calls;
    await run(a, force: false);
    expect(cloud.calls, count);
    cloud.offline = false;
    cloud.lose = true;
    await expectLater(run(a), throwsA(isA<SyncFailure>()));
    expect(cloud.changes, hasLength(1));
    await run(a);
    expect(cloud.changes, hasLength(2));
    expect(await a.pendingSyncCount('p'), 0);
    await run(a);
    expect(cloud.changes, hasLength(2));
    await run(b);
    expect(await b.pendingSyncCount('p'), 0);
    expect(
      (await b.read('p')).where((r) => r.record is LabResult),
      hasLength(1),
    );
  });
  test('two devices retain both edits; explicit local choice uses new operation against current server version', () async {
    await run(a);
    await run(b);
    await save(a, lab('6,00'));
    await save(a, lab('6,50'));
    await save(b, lab('7,00'));
    await run(a);
    await run(b);
    final conflict = (await b.syncConflicts('p')).single;
    expect((conflict.local.record as LabResult).value.raw, '7,00');
    expect((conflict.remote.record as LabResult).value.raw, '6,50');
    expect(await b.pendingSyncCount('p'), 1);
    await b.resolveSyncConflict(
      'p',
      'r',
      keepLocal: true,
      operationId: 'resolve',
      localRevision: conflict.local.revision,
      remoteVersion: conflict.remote.version,
    );
    await run(b);
    await run(a);
    expect(
      ((await a.read('p')).singleWhere((e) => e.record is LabResult).record
              as LabResult)
          .value
          .raw,
      '7,00',
    );
    expect(await b.pendingSyncCount('p'), 0);
    expect(await b.history('p', 'r'), hasLength(3));
  });
  test('remote deletion conflicts with pending edit; choosing server preserves a tombstone and history', () async {
    await run(a);
    await run(b);
    await save(b, lab('8'));
    await save(a, lab('5,00'), delete: true);
    await run(a);
    await run(b);
    final c = (await b.syncConflicts('p')).single;
    expect(c.remote.deleted, isTrue);
    await b.resolveSyncConflict(
      'p',
      'r',
      keepLocal: false,
      operationId: 'use-server',
      localRevision: c.local.revision,
      remoteVersion: c.remote.version,
    );
    expect((await b.read('p')).where((e) => e.record is LabResult), isEmpty);
    expect((await b.history('p', 'r')).first.deleted, isTrue);
    await run(b);
    expect(cloud.current['r']!.deleted, isTrue);
  });
  test('pull and cursor rollback together; stale resolutions and account switches cannot discard edits', () async {
    await run(a);
    await b.customStatement(
      "CREATE TRIGGER fail_pull BEFORE INSERT ON record_history WHEN NEW.record_id='r' BEGIN SELECT RAISE(ABORT,'synthetic crash'); END",
    );
    await expectLater(run(b), throwsA(isA<Exception>()));
    expect((await b.syncScope('p'))!.cursor, 0);
    expect(await b.read('p'), isEmpty);
    await b.customStatement('DROP TRIGGER fail_pull');
    await run(b);
    await save(a, lab('6'));
    await save(b, lab('7'));
    await run(a);
    await run(b);
    final c = (await b.syncConflicts('p')).single;
    await save(b, lab('8'));
    await expectLater(
      b.resolveSyncConflict(
        'p',
        'r',
        keepLocal: false,
        operationId: 'stale',
        localRevision: c.local.revision,
        remoteVersion: c.remote.version,
      ),
      throwsA(isA<RecordConflict>()),
    );
    await expectLater(
      b.bindSync('p', 'other', 'other-device', await cloud.identity()),
      throwsA(isA<SyncFailure>()),
    );
    expect(
      (await b.syncConflicts('p')).single.local.revision,
      greaterThan(c.local.revision),
    );
  });
  test('late response to a superseded operation cannot recreate a resolved conflict', () async {
    await run(a);
    await run(b);
    await save(b, lab('7'));
    final old = (await b.nextSyncCommand('p'))!;
    await save(a, lab('6'));
    await run(a);
    await run(b);
    final conflict = (await b.syncConflicts('p')).single;
    await b.resolveSyncConflict(
      'p',
      'r',
      keepLocal: true,
      operationId: 'resolve-new',
      localRevision: conflict.local.revision,
      remoteVersion: conflict.remote.version,
    );
    await run(b);
    final response = await cloud.push(old, 'epoch');
    expect(response.applied, isFalse);
    await b.acceptSyncReply('p', old, response);
    expect(await b.syncConflicts('p'), isEmpty);
    expect(
      ((await b.read('p')).singleWhere((e) => e.record is LabResult).record
              as LabResult)
          .value
          .raw,
      '7',
    );
  });
  test(
    'a receipt for another operation/device cannot acknowledge local data',
    () async {
      final command = (await a.nextSyncCommand('p'))!;
      final forged = RemoteRecord(
        payload: command.payload,
        version: 1,
        deleted: false,
        sequence: 1,
        deviceId: 'other-device',
        operationId: 'other-operation',
      );
      await expectLater(
        a.acceptSyncReply('p', command, SyncReply(true, forged)),
        throwsA(isA<SyncFailure>()),
      );
      expect(await a.pendingSyncCount('p'), 2);
      expect((await a.syncScope('p'))!.cursor, 0);
    },
  );
  test(
    'receipt JSON key order does not change the acknowledged medical payload',
    () async {
      final command = (await a.nextSyncCommand('p'))!;
      final reordered = Map<String, dynamic>.fromEntries(
        command.payload.entries.toList().reversed,
      );
      await a.acceptSyncReply(
        'p',
        command,
        SyncReply(
          true,
          RemoteRecord(
            payload: reordered,
            version: 1,
            deleted: false,
            sequence: 1,
            deviceId: command.deviceId,
            operationId: command.operationId,
          ),
        ),
      );
      expect(await a.pendingSyncCount('p'), 1);
    },
  );
  test('schema4 migration leaves legacy outbox payloads untouched', () async {
    final before = await a
        .customSelect('SELECT request FROM outbox ORDER BY rowid')
        .get();
    for (final table in [
      'sync_scopes',
      'sync_versions',
      'sync_attempts',
      'sync_acks',
      'sync_conflicts',
      'sync_remote_history',
    ]) {
      await a.customStatement('DROP TABLE $table');
    }
    await a.customStatement('PRAGMA user_version=4');
    await a.close();
    a = RecordsDatabase(NativeDatabase(File('${temp.path}/a.sqlite')));
    expect(
      (await a.customSelect('SELECT request FROM outbox ORDER BY rowid').get())
          .map((r) => r.read<String>('request')),
      before.map((r) => r.read<String>('request')),
    );
    expect(await a.pendingSyncCount('p'), 2);
    expect(await a.syncScope('p'), isNull);
  });
}
