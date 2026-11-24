import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:medical_domain/medical_domain.dart';

import 'record_codec.dart';

/// SQL schema and transactions stay here; only domain values cross the port.
final class RecordsDatabase extends GeneratedDatabase
    implements HealthRecordsRepository {
  RecordsDatabase(super.executor, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  static const recordsSql = '''CREATE TABLE records (
    id TEXT PRIMARY KEY NOT NULL, profile_id TEXT NOT NULL,
    kind TEXT NOT NULL, payload TEXT NOT NULL,
    revision INTEGER NOT NULL CHECK (revision > 0),
    deleted INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0, 1)),
    updated_at TEXT NOT NULL
  )''';
  static const outboxSql = '''CREATE TABLE outbox (
    operation_id TEXT PRIMARY KEY NOT NULL, profile_id TEXT NOT NULL,
    record_id TEXT NOT NULL, revision INTEGER NOT NULL,
    request TEXT NOT NULL, created_at TEXT NOT NULL
  )''';
  static const historySql = '''CREATE TABLE record_history (
    record_id TEXT NOT NULL, profile_id TEXT NOT NULL, revision INTEGER NOT NULL,
    payload TEXT NOT NULL, deleted INTEGER NOT NULL, changed_at TEXT NOT NULL,
    PRIMARY KEY (record_id, revision)
  )''';

  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    OnCreateQuery(recordsSql),
    OnCreateQuery(outboxSql),
    OnCreateQuery(historySql),
    OnCreateQuery(
      'CREATE INDEX records_profile ON records(profile_id, deleted)',
    ),
  ];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from != 1 || to != 2) {
        throw StateError('Unsupported database migration');
      }
      await transaction(() async {
        await customStatement(historySql);
        await customStatement(
          '''INSERT INTO record_history
          SELECT id, profile_id, revision, payload, deleted, updated_at FROM records''',
        );
        await customStatement(
          'CREATE INDEX records_profile ON records(profile_id, deleted)',
        );
      });
    },
    beforeOpen: (details) async {
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw StateError('Database was created by a newer app');
      }
    },
  );

  RecordEntry _entry(QueryRow row) => RecordEntry(
    decodeRecord(
      jsonDecode(row.read<String>('payload')) as Map<String, dynamic>,
    ),
    row.read<int>('revision'),
    deleted: row.read<int>('deleted') != 0,
  );

  @override
  Future<List<RecordEntry>> read(String profileId) async => (await customSelect(
    '''SELECT * FROM records
        WHERE profile_id = ? AND deleted = 0 ORDER BY updated_at DESC, id''',
    variables: [Variable(profileId)],
  ).get()).map(_entry).toList(growable: false);

  @override
  Future<List<RecordEntry>> history(String profileId, String recordId) async =>
      (await customSelect(
        '''SELECT * FROM record_history
        WHERE profile_id = ? AND record_id = ? ORDER BY revision DESC''',
        variables: [Variable(profileId), Variable(recordId)],
      ).get()).map(_entry).toList(growable: false);

  @override
  Future<int> commit(RecordMutation mutation) async {
    mutation.record.validate();
    if (mutation.operationId.trim().isEmpty ||
        mutation.expectedRevision < 0 ||
        (mutation.delete && mutation.record is MedicalProfile)) {
      throw const InvalidRecord('operation');
    }
    final r = mutation.record;
    final payload = jsonEncode(encodeRecord(r));
    final request = jsonEncode({
      'payload': encodeRecord(r),
      'expectedRevision': mutation.expectedRevision,
      'delete': mutation.delete,
    });
    return transaction(() async {
      final previousOperation = await customSelect(
        'SELECT request, revision FROM outbox WHERE operation_id = ?',
        variables: [Variable(mutation.operationId)],
      ).getSingleOrNull();
      if (previousOperation != null) {
        if (previousOperation.read<String>('request') != request) {
          throw const OperationMismatch();
        }
        return previousOperation.read<int>('revision');
      }
      final previous = await customSelect(
        'SELECT * FROM records WHERE id = ?',
        variables: [Variable(r.id)],
      ).getSingleOrNull();
      if ((previous?.read<int>('revision') ?? 0) != mutation.expectedRevision ||
          (previous != null &&
              (previous.read<String>('profile_id') != r.profileId ||
                  previous.read<String>('kind') != r.kind.name ||
                  previous.read<int>('deleted') != 0)) ||
          (previous == null && mutation.delete)) {
        throw const RecordConflict();
      }
      if (r is! MedicalProfile) {
        final owner = await customSelect(
          '''SELECT id FROM records
          WHERE id = ? AND profile_id = ? AND kind = 'profile' AND deleted = 0''',
          variables: [Variable(r.profileId), Variable(r.profileId)],
        ).getSingleOrNull();
        if (owner == null) throw const InvalidRecord('profileId');
      }
      final revision = mutation.expectedRevision + 1;
      final now = _clock().toUtc().toIso8601String();
      final deleted = mutation.delete ? 1 : 0;
      await customStatement(
        '''INSERT INTO records
        (id, profile_id, kind, payload, revision, deleted, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET payload = excluded.payload,
          revision = excluded.revision, deleted = excluded.deleted,
          updated_at = excluded.updated_at''',
        [r.id, r.profileId, r.kind.name, payload, revision, deleted, now],
      );
      await customStatement(
        '''INSERT INTO record_history
        (record_id, profile_id, revision, payload, deleted, changed_at)
        VALUES (?, ?, ?, ?, ?, ?)''',
        [r.id, r.profileId, revision, payload, deleted, now],
      );
      await customStatement(
        '''INSERT INTO outbox
        (operation_id, profile_id, record_id, revision, request, created_at)
        VALUES (?, ?, ?, ?, ?, ?)''',
        [mutation.operationId, r.profileId, r.id, revision, request, now],
      );
      return revision;
    });
  }
}
