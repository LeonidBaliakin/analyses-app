import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';
import 'package:local_store/src/record_codec.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const profile = MedicalProfile(id: 'p', name: 'Synthetic profile');
LabResult result({
  String laboratory = 'Synthetic lab',
  String raw = '< 0,0100',
  LabResultCoding? coding,
}) => LabResult(
  id: 'r',
  profileId: 'p',
  name: 'Synthetic test',
  date: CalendarDate(2026, 11, 24),
  category: AnalysisCategory.blood,
  value: SourceValue(raw, ResultValueKind.comparison),
  laboratory: laboratory,
  unit: 'test-unit',
  reference: 'source reference',
  method: 'source method',
  specimen: 'source specimen',
  coding: coding,
);
RecordMutation command(
  String id,
  HealthRecord record, {
  int revision = 0,
  bool delete = false,
}) => RecordMutation(
  operationId: id,
  record: record,
  expectedRevision: revision,
  delete: delete,
);

void main() {
  late Directory directory;
  late File file;
  late RecordsDatabase db;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('analyses-records-');
    file = File('${directory.path}/records.sqlite');
    db = RecordsDatabase(NativeDatabase(file));
  });
  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });

  const coding = LabResultCoding(
    terminologyReleaseId: 'synthetic-v1',
    indicatorId: 'synthetic-indicator',
    unitId: 'synthetic-unit',
    sourceName: 'Synthetic test',
    sourceUnit: 'test-unit',
    sourceLaboratory: 'Synthetic lab',
    sourceSpecimen: 'source specimen',
    sourceMethod: 'source method',
  );
  test(
    'coding, originals, history and outbox survive restart and replay',
    () async {
      await db.commit(command('p1', profile));
      await db.commit(command('raw-r', result()));
      final selected = result(coding: coding);
      final mutation = command('coded-r', selected, revision: 1);
      expect(await db.commit(mutation), 2);
      await db.close();
      db = RecordsDatabase(NativeDatabase(file));
      expect(await db.commit(mutation), 2);
      final read =
          (await db.read('p')).singleWhere((e) => e.record is LabResult).record
              as LabResult;
      expect(read.value.raw, '< 0,0100');
      expect(read.unit, 'test-unit');
      expect(read.coding!.terminologyReleaseId, 'synthetic-v1');
      expect(read.coding!.indicatorId, 'synthetic-indicator');
      expect(read.coding!.unitId, 'synthetic-unit');
      expect(read.coding!.sourceSpecimen, 'source specimen');
      final history = await db.history('p', 'r');
      expect(history, hasLength(2));
      expect((history.last.record as LabResult).coding, isNull);
      expect(
        (history.first.record as LabResult).coding!.verification,
        'userConfirmed',
      );
      final outbox = await db
          .customSelect(
            "SELECT request FROM outbox WHERE operation_id = 'coded-r'",
          )
          .getSingle();
      final request =
          jsonDecode(outbox.read<String>('request')) as Map<String, dynamic>;
      expect(
        request['payload']['coding']['indicatorId'],
        'synthetic-indicator',
      );
      expect(request['payload']['coding']['scope'], 'record');
      expect(await db.customSelect('SELECT * FROM outbox').get(), hasLength(3));
    },
  );

  test(
    'a failed coded revision rolls back current record, history and outbox',
    () async {
      await db.commit(command('p1', profile));
      await db.commit(command('raw-r', result()));
      await db.customStatement('''CREATE TRIGGER fail_coded_outbox
      BEFORE INSERT ON outbox WHEN NEW.operation_id = 'coded-r'
      BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END''');
      await expectLater(
        db.commit(command('coded-r', result(coding: coding), revision: 1)),
        throwsA(isA<Exception>()),
      );
      final history = await db.history('p', 'r');
      expect(history, hasLength(1));
      expect((history.single.record as LabResult).coding, isNull);
      expect(
        ((await db.read('p')).singleWhere((e) => e.record is LabResult).record
                as LabResult)
            .coding,
        isNull,
      );
      expect(
        await db
            .customSelect("SELECT * FROM outbox WHERE operation_id = 'coded-r'")
            .get(),
        isEmpty,
      );
    },
  );

  test('legacy payload and operation fingerprints remain unchanged', () async {
    await db.commit(command('p1', profile));
    final legacyPayload = <String, Object?>{
      'format': 1,
      'id': 'r',
      'profileId': 'p',
      'kind': 'result',
      'source': 'manual',
      'name': 'Synthetic test',
      'raw': '< 0,0100',
      'valueKind': 'comparison',
      'date': '2026-11-24',
      'category': 'blood',
      'unit': 'test-unit',
      'reference': 'source reference',
      'laboratory': 'Synthetic lab',
      'method': 'source method',
      'specimen': 'source specimen',
      'notes': '',
    };
    final encoded = jsonEncode(legacyPayload);
    final request = jsonEncode({
      'payload': legacyPayload,
      'expectedRevision': 0,
      'delete': false,
    });
    await db.customStatement(
      'INSERT INTO records VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['r', 'p', 'result', encoded, 1, 0, 'fixture'],
    );
    await db.customStatement(
      'INSERT INTO record_history VALUES (?, ?, ?, ?, ?, ?)',
      ['r', 'p', 1, encoded, 0, 'fixture'],
    );
    await db.customStatement('INSERT INTO outbox VALUES (?, ?, ?, ?, ?, ?)', [
      'old-r',
      'p',
      'r',
      1,
      request,
      'fixture',
    ]);
    expect(jsonEncode(encodeRecord(result())), encoded);
    await db.close();
    db = RecordsDatabase(NativeDatabase(file));
    expect(await db.commit(command('old-r', result())), 1);
    expect((await db.history('p', 'r')).single.revision, 1);
    expect(
      ((await db.read('p')).singleWhere((e) => e.record is LabResult).record
              as LabResult)
          .coding,
      isNull,
    );
  });

  test('unknown payload versions and coding provenance fail explicitly', () {
    final encoded = encodeRecord(result(coding: coding));
    final j = jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
    j['coding']['verification'] = 'modelGuess';
    expect(() => decodeRecord(j), throwsFormatException);
    expect(
      () => decodeRecord({...encodeRecord(profile), 'format': 2}),
      throwsFormatException,
    );
    final stale = jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
    stale['laboratory'] = 'Different lab';
    expect(() => decodeRecord(stale), throwsA(isA<InvalidRecord>()));
    expect(
      () => decodeRecord({...encoded, 'format': 4}),
      throwsFormatException,
    );
  });

  test(
    'all record kinds and outbox survive close and reopen without network',
    () async {
      final records = <HealthRecord>[
        profile,
        result(),
        MedicationCourse(
          id: 'c',
          profileId: 'p',
          name: 'Synthetic course',
          start: CalendarDate(2025, 1, 1),
        ),
        HomeMeasurement(
          id: 'm',
          profileId: 'p',
          name: 'Synthetic measurement',
          date: CalendarDate(2026, 11, 24),
          value: const SourceValue('5,200', ResultValueKind.numeric),
          minuteOfDay: 800,
          utcOffsetMinutes: 180,
        ),
      ];
      for (final r in records) {
        await db.commit(command('op-${r.id}', r));
      }
      await db.close();
      db = RecordsDatabase(NativeDatabase(file));
      final loaded = await db.read('p');
      expect(loaded, hasLength(4));
      final lab = loaded.map((e) => e.record).whereType<LabResult>().single;
      expect(lab.value.raw, '< 0,0100');
      expect(lab.method, 'source method');
      expect(lab.reference, 'source reference');
      expect(lab.unit, 'test-unit');
      final home = loaded
          .map((e) => e.record)
          .whereType<HomeMeasurement>()
          .single;
      expect(home.value.raw, '5,200');
      expect(home.utcOffsetMinutes, 180);
      expect(await db.customSelect('SELECT * FROM outbox').get(), hasLength(4));
    },
  );
  test('lost acknowledgement can be retried without a duplicate revision or outbox entry', () async {
    final mutation = command('same-operation', profile);
    expect(await db.commit(mutation), 1);
    expect(await db.commit(mutation), 1);
    expect(await db.read('p'), hasLength(1));
    expect(await db.history('p', 'p'), hasLength(1));
    expect(await db.customSelect('SELECT * FROM outbox').get(), hasLength(1));
    await expectLater(
      db.commit(
        command(
          'same-operation',
          const MedicalProfile(id: 'p', name: 'Changed'),
        ),
      ),
      throwsA(isA<OperationMismatch>()),
    );
  });
  test('outbox failure rolls back current record and history in the same transaction', () async {
    await db.commit(command('p1', profile));
    await db.customStatement(
      '''CREATE TRIGGER reject_synthetic_outbox BEFORE INSERT ON outbox
      BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END''',
    );
    await expectLater(db.commit(command('r1', result())), throwsA(anything));
    expect(await db.read('p'), hasLength(1));
    expect(await db.history('p', 'r'), isEmpty);
    await db.customStatement('DROP TRIGGER reject_synthetic_outbox');
    expect(await db.commit(command('r1', result())), 1);
  });
  test(
    'stale edits from another connection cannot overwrite confirmed values',
    () async {
      await db.commit(command('p1', profile));
      await db.commit(command('r1', result()));
      final other = RecordsDatabase(NativeDatabase(file));
      try {
        expect(
          (await other.read('p'))
              .where((e) => e.record.id == 'r')
              .single
              .revision,
          1,
        );
        await db.commit(command('r2', result(raw: '< 0,0200'), revision: 1));
        await expectLater(
          other.commit(command('stale', result(raw: '< 0,0300'), revision: 1)),
          throwsA(isA<RecordConflict>()),
        );
        final versions = await other.history('p', 'r');
        expect(versions, hasLength(2));
        expect((versions.last.record as LabResult).value.raw, '< 0,0100');
        expect((versions.first.record as LabResult).value.raw, '< 0,0200');
      } finally {
        await other.close();
      }
    },
  );
  test(
    'delete keeps tombstone and revisions and repeated delivery is harmless',
    () async {
      await db.commit(command('p1', profile));
      await db.commit(command('r1', result()));
      final deletion = command('delete-r', result(), revision: 1, delete: true);
      expect(await db.commit(deletion), 2);
      expect(await db.commit(deletion), 2);
      expect(await db.read('p'), hasLength(1));
      final history = await db.history('p', 'r');
      expect(history, hasLength(2));
      expect(history.first.deleted, isTrue);
      await expectLater(
        db.commit(command('resurrect', result(), revision: 2)),
        throwsA(isA<RecordConflict>()),
      );
    },
  );
  test(
    'profile scope is checked and source names never trigger merging',
    () async {
      await expectLater(
        db.commit(command('orphan', result())),
        throwsA(isA<InvalidRecord>()),
      );
      await db.commit(command('p1', profile));
      await db.commit(command('r1', result()));
      await db.commit(
        command(
          'other-p',
          const MedicalProfile(id: 'q', name: 'Other synthetic profile'),
        ),
      );
      final foreign = LabResult(
        id: 'r',
        profileId: 'q',
        name: 'Other',
        value: const SourceValue('2', ResultValueKind.numeric),
        date: CalendarDate(2026, 11, 24),
        category: AnalysisCategory.blood,
      );
      await expectLater(
        db.commit(command('foreign', foreign, revision: 1)),
        throwsA(isA<RecordConflict>()),
      );
      final second = LabResult(
        id: 'r-second',
        profileId: 'p',
        name: 'Synthetic test',
        laboratory: 'Different synthetic lab',
        unit: 'other-unit',
        value: const SourceValue('negative', ResultValueKind.qualitative),
        date: CalendarDate(2026, 11, 24),
        category: AnalysisCategory.blood,
      );
      await db.commit(command('second', second));
      expect(
        (await db.read('p')).where((e) => e.record is LabResult),
        hasLength(2),
      );
      expect(await db.history('q', 'r'), isEmpty);
    },
  );
  test(
    'schema v1 migration preserves original payloads and pending operations',
    () async {
      await db.close();
      final legacy = sqlite3.open(file.path);
      legacy.execute(RecordsDatabase.recordsSql);
      legacy.execute(RecordsDatabase.outboxSql);
      final payload = jsonEncode(encodeRecord(profile));
      legacy.execute('INSERT INTO records VALUES (?, ?, ?, ?, ?, ?, ?)', [
        'p',
        'p',
        'profile',
        payload,
        1,
        0,
        '2026-11-24T00:00:00Z',
      ]);
      legacy.execute('INSERT INTO outbox VALUES (?, ?, ?, ?, ?, ?)', [
        'legacy-op',
        'p',
        'p',
        1,
        'original-request',
        '2026-11-24T00:00:00Z',
      ]);
      legacy.execute('PRAGMA user_version = 1');
      legacy.close();
      db = RecordsDatabase(NativeDatabase(file));
      expect((await db.read('p')).single.record, isA<MedicalProfile>());
      expect((await db.history('p', 'p')).single.revision, 1);
      expect(
        (await db.customSelect('SELECT * FROM outbox').get()).single
            .read<String>('request'),
        'original-request',
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        5,
      );
    },
  );
  test('newer database is rejected without dropping data', () async {
    await db.commit(command('p1', profile));
    await db.close();
    final newer = sqlite3.open(file.path);
    newer.execute('PRAGMA user_version = 6');
    newer.close();
    db = RecordsDatabase(NativeDatabase(file));
    await expectLater(db.read('p'), throwsA(isA<StateError>()));
    final check = sqlite3.open(file.path);
    expect(check.select('SELECT * FROM records'), hasLength(1));
    expect(check.userVersion, 6);
    check.close();
  });
}
