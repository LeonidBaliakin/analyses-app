import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:document_domain/document_domain.dart';
import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File file;
  late RecordsDatabase db;
  final bytes = Uint8List.fromList(
    utf8.encode('%PDF-1.7\nSynthetic original\n%%EOF'),
  );
  OriginalDocument original({
    String profile = 'p',
    String name = '../../source.pdf',
  }) => OriginalDocument(
    documentId: 'd',
    originalId: 'o',
    profileId: profile,
    fileName: name,
    mime: 'application/pdf',
    size: bytes.length,
    sha256: originalSha256(bytes),
    importedAt: DateTime.utc(2026, 11, 24),
    importSource: 'files',
  );
  setUp(() async {
    directory = Directory.systemTemp.createTempSync('analyses-originals-');
    file = File('${directory.path}/records.sqlite');
    db = RecordsDatabase(NativeDatabase(file));
    await db.commit(
      const RecordMutation(
        operationId: 'profile',
        record: MedicalProfile(id: 'p', name: 'Synthetic profile'),
        expectedRevision: 0,
      ),
    );
  });
  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });
  test(
    'original survives restart; replay does not duplicate or change bytes',
    () async {
      await db.importOriginal(original(), bytes);
      await db.setOriginalCloudState(
        'p',
        'o',
        OriginalCloudState.pending,
        destinationId: 'synthetic-storage',
      );
      await db.close();
      db = RecordsDatabase(NativeDatabase(file));
      final stored = (await db.listOriginals('p')).single;
      expect(stored.fileName, '../../source.pdf');
      expect(stored.cloudState, OriginalCloudState.pending);
      expect(stored.cloudDestination, 'synthetic-storage');
      expect(await db.readOriginal('p', 'o'), bytes);
      await db.importOriginal(original(), bytes);
      expect(await db.listOriginals('p'), hasLength(1));
      await expectLater(
        db.importOriginal(original(name: 'changed.pdf'), bytes),
        throwsA(isA<OriginalFailure>()),
      );
      await expectLater(
        db.readOriginal('foreign-profile', 'o'),
        throwsA(isA<OriginalFailure>()),
      );
      expect(await db.listOriginals('foreign-profile'), isEmpty);
    },
  );
  test(
    'failed transaction, incorrect bytes and orphan import publish nothing',
    () async {
      await expectLater(
        db.importOriginal(original(), Uint8List.fromList([...bytes, 0])),
        throwsA(isA<OriginalFailure>()),
      );
      await expectLater(
        db.importOriginal(original(profile: 'missing'), bytes),
        throwsA(isA<OriginalFailure>()),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_original BEFORE INSERT ON originals BEGIN SELECT RAISE(ABORT,'synthetic failure'); END",
      );
      await expectLater(
        db.importOriginal(original(), bytes),
        throwsA(isA<Exception>()),
      );
      expect(await db.listOriginals('p'), isEmpty);
    },
  );
  test(
    'corrupt local bytes are detected before export or cloud upload',
    () async {
      await db.importOriginal(original(), bytes);
      await db.customStatement(
        "UPDATE originals SET bytes=x'0000' WHERE original_id='o'",
      );
      await expectLater(
        db.readOriginal('p', 'o'),
        throwsA(isA<OriginalFailure>()),
      );
    },
  );
  test(
    'v2 migration keeps records, history and unsent outbox byte-for-byte',
    () async {
      await db.close();
      final sql = sqlite3.open(file.path);
      sql.execute('DROP TABLE originals');
      for (final table in [
        'processing_jobs',
        'processing_drafts',
        'draft_history',
        'draft_confirmations',
        'confirmed_originals',
      ]) {
        sql.execute('DROP TABLE $table');
      }
      sql.execute('PRAGMA user_version = 2');
      final before = sql
          .select('SELECT payload FROM records')
          .single['payload'];
      final pending = sql
          .select('SELECT request FROM outbox')
          .single['request'];
      sql.close();
      db = RecordsDatabase(NativeDatabase(file));
      expect((await db.read('p')).single.record, isA<MedicalProfile>());
      expect((await db.history('p', 'p')).single.revision, 1);
      expect(
        (await db.customSelect('SELECT payload FROM records').getSingle())
            .read<String>('payload'),
        before,
      );
      expect(
        (await db.customSelect('SELECT request FROM outbox').getSingle())
            .read<String>('request'),
        pending,
      );
      await db.importOriginal(original(), bytes);
      expect(await db.readOriginal('p', 'o'), bytes);
    },
  );
}
