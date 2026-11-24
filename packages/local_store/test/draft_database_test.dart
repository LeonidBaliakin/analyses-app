import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File file;
  late RecordsDatabase db;
  final bytes = Uint8List.fromList(utf8.encode('%PDF-1.7\nSynthetic\n%%EOF'));
  final o = OriginalDocument(
    documentId: 'd',
    originalId: 'o',
    profileId: 'p',
    fileName: 'synthetic.pdf',
    mime: 'application/pdf',
    size: bytes.length,
    sha256: originalSha256(bytes),
    importedAt: DateTime.utc(2026),
    importSource: 'files',
  );
  ProcessingJob job(String id) => ProcessingJob(
    id: id,
    original: o,
    mode: ProcessingMode.local,
    terminologyReleaseId: 'terms1',
    runtimeId: 'runtime1',
  );
  ProcessingDraft draft(String id) => ProcessingDraft(
    jobId: id,
    originalId: 'o',
    documentId: 'd',
    profileId: 'p',
    originalSha256: o.sha256,
    mode: ProcessingMode.local,
    terminologyReleaseId: 'terms1',
    versions: {'ocr': 'o1', 'model': 'm1', 'worker': 'w1', 'prompt': 'p1'},
    pages: [
      {'number': 1, 'text': 'Synthetic raw'},
    ],
    rows: [
      for (var n = 0; n < 2; n++)
        DraftRow(
          id: 'row-$n',
          source: {'value': ExtractedField('0,0100', page: 1, start: 2)},
          review: {
            'name': 'Synthetic $n',
            'value': '0,0100',
            'date': '2026-11-24',
            'unit': 'mg/L',
          },
        ),
    ],
  );
  Future<ProcessingDraft> create(String id) async {
    await db.createProcessingJob(job(id));
    return db.storeGeneratedDraft(draft(id));
  }

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');
  setUp(() async {
    directory = Directory.systemTemp.createTempSync('draft-store-');
    file = File('${directory.path}/records.sqlite');
    db = RecordsDatabase(NativeDatabase(file));
    await db.commit(
      const RecordMutation(
        operationId: 'profile',
        record: MedicalProfile(id: 'p', name: 'Synthetic'),
        expectedRevision: 0,
      ),
    );
    await db.importOriginal(o, bytes);
  });
  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });
  test('draft edits and OCR survive restart; no records until explicit confirmation', () async {
    final d = await create('j');
    expect(await count('records'), 1);
    expect(await count('outbox'), 1);
    final edit = d.edited([
      d.rows.first.edit({...d.rows.first.review, 'value': '0,0200'}),
      d.rows.last,
    ]);
    final saved = await db.saveDraft(edit, 1);
    expect(saved.revision, 2);
    expect((await db.saveDraft(edit, 1)).revision, 2); // lost save response
    await db.close();
    db = RecordsDatabase(NativeDatabase(file));
    final restored = (await db.readDraft('p', 'j'))!;
    expect(restored.rows.first.review['value'], '0,0200');
    expect(restored.rows.first.source['value']!.raw, '0,0100');
    expect(await db.readDraft('foreign', 'j'), isNull);
    expect(
      (await db.storeGeneratedDraft(d)).revision,
      2,
    ); // repeated model delivery
    await expectLater(db.saveDraft(d, 1), throwsA(isA<RecordConflict>()));
    expect(await count('records'), 1);
    expect(await count('draft_history'), 2);
  });
  test('confirmation, medical records, history and outbox are one transaction and replay once', () async {
    final d = await create('j');
    await db.customStatement(
      "CREATE TRIGGER fail_second BEFORE INSERT ON records WHEN NEW.id='import-o-row-1' BEGIN SELECT RAISE(ABORT,'synthetic crash'); END",
    );
    await expectLater(
      db.confirmDraft(d, 'confirm', 1),
      throwsA(isA<Exception>()),
    );
    expect(await count('records'), 1);
    expect(await count('outbox'), 1);
    expect(await count('record_history'), 1);
    expect(await count('draft_confirmations'), 0);
    expect(await count('confirmed_originals'), 0);
    expect((await db.readDraft('p', 'j'))!.confirmed, isFalse);
    await db.customStatement('DROP TRIGGER fail_second');
    final ids = await db.confirmDraft(d, 'confirm', 1);
    expect(ids, hasLength(2));
    await db.close();
    db = RecordsDatabase(NativeDatabase(file));
    expect(await db.confirmDraft(d, 'confirm', 1), ids);
    expect(await count('records'), 3);
    expect(await count('outbox'), 3);
    expect(await count('record_history'), 3);
    expect(await count('draft_confirmations'), 1);
    final records = await db.read('p');
    final result = records.map((r) => r.record).whereType<LabResult>().first;
    expect(result.documentSource!.fields['value'], '0,0100');
    expect(result.documentSource!.jobId, 'j');
    final repeat = await create('other-job');
    await expectLater(
      db.confirmDraft(repeat, 'other-confirm', 1),
      throwsA(isA<ProcessingFailure>()),
    );
    expect(await db.readOriginal('p', 'o'), bytes);
  });
  test(
    'provenance, revision, cancellation and job request bindings cannot change',
    () async {
      final d = await create('j');
      final altered = d.edited([
        DraftRow(
          id: 'row-0',
          source: {'value': const ExtractedField('invented')},
          review: d.rows.first.review,
        ),
        d.rows.last,
      ]);
      await expectLater(
        db.saveDraft(altered, 1),
        throwsA(isA<ProcessingFailure>()),
      );
      await db.createProcessingJob(job('cancelled'));
      await db.setProcessingStatus(
        'p',
        'cancelled',
        ProcessingStatus.cancelled,
      );
      await expectLater(
        db.storeGeneratedDraft(draft('cancelled')),
        throwsA(isA<ProcessingFailure>()),
      );
      await expectLater(
        db.createProcessingJob(
          ProcessingJob(
            id: 'j',
            original: o,
            mode: ProcessingMode.ownServer,
            terminologyReleaseId: 'terms1',
            runtimeId: 'runtime1',
          ),
        ),
        throwsA(isA<OperationMismatch>()),
      );
      await expectLater(
        db.confirmDraft(d, 'op', 2),
        throwsA(isA<RecordConflict>()),
      );
    },
  );
  test(
    'schema3 original and legacy outbox migrate without alteration',
    () async {
      for (final table in [
        'sync_scopes',
        'sync_versions',
        'sync_attempts',
        'sync_acks',
        'sync_conflicts',
        'sync_remote_history',
        'processing_jobs',
        'processing_drafts',
        'draft_history',
        'draft_confirmations',
        'confirmed_originals',
      ]) {
        await db.customStatement('DROP TABLE $table');
      }
      await db.customStatement('PRAGMA user_version=3');
      await db.close();
      db = RecordsDatabase(NativeDatabase(file));
      expect(await db.readOriginal('p', 'o'), bytes);
      expect(await count('outbox'), 1);
      expect(await count('records'), 1);
      expect(await db.processingJobs('p', 'o'), isEmpty);
      await create('migrated');
      expect(await count('processing_drafts'), 1);
    },
  );
}
