import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:document_domain/document_domain.dart';

import 'record_codec.dart';

/// SQL schema and transactions stay here; only domain values cross the port.
final class RecordsDatabase extends GeneratedDatabase
    implements HealthRecordsRepository, OriginalRepository {
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

  static const originalsSql = '''CREATE TABLE originals (
    original_id TEXT PRIMARY KEY NOT NULL, document_id TEXT NOT NULL UNIQUE,
    profile_id TEXT NOT NULL, file_name TEXT NOT NULL, mime TEXT NOT NULL,
    byte_size INTEGER NOT NULL, sha256 TEXT NOT NULL, imported_at TEXT NOT NULL,
    import_source TEXT NOT NULL, cloud_state TEXT NOT NULL, cloud_destination TEXT, bytes BLOB NOT NULL
  )''';

  @override
  int get schemaVersion => 3;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    OnCreateQuery(recordsSql),
    OnCreateQuery(outboxSql),
    OnCreateQuery(historySql),
    OnCreateQuery(originalsSql),
    OnCreateQuery(
      'CREATE INDEX records_profile ON records(profile_id, deleted)',
    ),
  ];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 1 || from > 2 || to != 3) {
        throw StateError('Unsupported database migration');
      }
      await transaction(() async {
        if (from == 1) {
          await customStatement(historySql);
          await customStatement(
            '''INSERT INTO record_history
          SELECT id, profile_id, revision, payload, deleted, updated_at FROM records''',
          );
          await customStatement(
            'CREATE INDEX records_profile ON records(profile_id, deleted)',
          );
        }
        await customStatement(originalsSql);
      });
    },
    beforeOpen: (details) async {
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw StateError('Database was created by a newer app');
      }
    },
  );

  OriginalDocument _original(QueryRow row) => OriginalDocument(
    cloudDestination: row.readNullable<String>('cloud_destination'),
    documentId: row.read<String>('document_id'),
    originalId: row.read<String>('original_id'),
    profileId: row.read<String>('profile_id'),
    fileName: row.read<String>('file_name'),
    mime: row.read<String>('mime'),
    size: row.read<int>('byte_size'),
    sha256: row.read<String>('sha256'),
    importedAt: DateTime.parse(row.read<String>('imported_at')),
    importSource: row.read<String>('import_source'),
    cloudState: OriginalCloudState.values.byName(
      row.read<String>('cloud_state'),
    ),
  );

  @override
  Future<void> importOriginal(
    OriginalDocument original,
    Uint8List bytes,
  ) async {
    final copy = Uint8List.fromList(bytes);
    original.verify(copy);
    await transaction(() async {
      final owner = await customSelect(
        "SELECT id FROM records WHERE id = ? AND kind = 'profile' AND deleted = 0",
        variables: [Variable(original.profileId)],
      ).getSingleOrNull();
      if (owner == null) throw const OriginalFailure('profile');
      final existing = await customSelect(
        'SELECT * FROM originals WHERE original_id = ?',
        variables: [Variable(original.originalId)],
      ).getSingleOrNull();
      if (existing != null) {
        final old = _original(existing);
        if (old.profileId != original.profileId ||
            old.documentId != original.documentId ||
            old.sha256 != original.sha256 ||
            old.size != original.size ||
            old.mime != original.mime ||
            old.fileName != original.fileName ||
            old.importSource != original.importSource ||
            old.importedAt != original.importedAt) {
          throw const OriginalFailure('conflict');
        }
        old.verify(existing.read<Uint8List>('bytes'));
        return;
      }
      await customStatement(
        '''INSERT INTO originals VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          original.originalId,
          original.documentId,
          original.profileId,
          original.fileName,
          original.mime,
          original.size,
          original.sha256,
          original.importedAt.toIso8601String(),
          original.importSource,
          OriginalCloudState.local.name,
          null,
          copy,
        ],
      );
    });
  }

  @override
  Future<List<OriginalDocument>> listOriginals(String profileId) async =>
      (await customSelect(
        'SELECT * FROM originals WHERE profile_id = ? ORDER BY imported_at DESC, original_id',
        variables: [Variable(profileId)],
      ).get()).map(_original).toList(growable: false);

  @override
  Future<Uint8List> readOriginal(String profileId, String originalId) async {
    final row = await customSelect(
      'SELECT * FROM originals WHERE profile_id = ? AND original_id = ?',
      variables: [Variable(profileId), Variable(originalId)],
    ).getSingleOrNull();
    if (row == null) throw const OriginalFailure('missing');
    final bytes = row.read<Uint8List>('bytes');
    _original(row).verify(bytes);
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> setOriginalCloudState(
    String profileId,
    String originalId,
    OriginalCloudState state, {
    String? destinationId,
  }) async {
    if (state != OriginalCloudState.local &&
        (destinationId == null || destinationId.isEmpty)) {
      throw const OriginalFailure('connection');
    }
    await customStatement(
      'UPDATE originals SET cloud_state = ?, cloud_destination = ? WHERE profile_id = ? AND original_id = ?',
      [state.name, destinationId, profileId, originalId],
    );
  }

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
