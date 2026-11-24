import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';

mixin SyncStorage on GeneratedDatabase implements SyncStore {
  static const schema = [
    '''CREATE TABLE sync_scopes(profile_id TEXT PRIMARY KEY,destination TEXT NOT NULL,device_id TEXT NOT NULL,epoch TEXT NOT NULL,cursor INTEGER NOT NULL DEFAULT 0,attempts INTEGER NOT NULL DEFAULT 0,error TEXT,retry_at TEXT,last_success TEXT)''',
    '''CREATE TABLE sync_versions(profile_id TEXT,record_id TEXT,version INTEGER NOT NULL,PRIMARY KEY(profile_id,record_id))''',
    '''CREATE TABLE sync_attempts(operation_id TEXT PRIMARY KEY,request TEXT NOT NULL)''',
    '''CREATE TABLE sync_acks(operation_id TEXT PRIMARY KEY,reason TEXT NOT NULL)''',
    '''CREATE TABLE sync_conflicts(profile_id TEXT,record_id TEXT,remote TEXT NOT NULL,PRIMARY KEY(profile_id,record_id))''',
    '''CREATE TABLE sync_remote_history(profile_id TEXT,record_id TEXT,version INTEGER,payload TEXT NOT NULL,PRIMARY KEY(profile_id,record_id,version))''',
  ];
  DateTime get syncNow => DateTime.now();
  @override
  Future<SyncScope?> syncScope(String profile) async {
    final r = await customSelect(
      'SELECT * FROM sync_scopes WHERE profile_id=?',
      variables: [Variable(profile)],
    ).getSingleOrNull();
    if (r == null) return null;
    DateTime? date(String k) => r.readNullable<String>(k) == null
        ? null
        : DateTime.parse(r.read<String>(k));
    return SyncScope(
      destination: r.read<String>('destination'),
      deviceId: r.read<String>('device_id'),
      epoch: r.read<String>('epoch'),
      cursor: r.read<int>('cursor'),
      attempts: r.read<int>('attempts'),
      error: r.readNullable<String>('error'),
      retryAt: date('retry_at'),
      lastSuccess: date('last_success'),
    );
  }

  @override
  Future<void> bindSync(
    String profile,
    String destination,
    String deviceId,
    SyncIdentity identity,
  ) => transaction(() async {
    if (identity.profileId != profile ||
        identity.epoch.isEmpty ||
        identity.ownerId.isEmpty) {
      throw const SyncFailure('scope');
    }
    final old = await syncScope(profile);
    if (old != null) {
      if (old.destination != destination) throw const SyncFailure('account');
      if (old.epoch != identity.epoch) {
        throw const SyncFailure('server_changed');
      }
      return;
    }
    await customStatement(
      'INSERT INTO sync_scopes(profile_id,destination,device_id,epoch) VALUES(?,?,?,?)',
      [profile, destination, deviceId, identity.epoch],
    );
  });
  Future<int> _remoteVersion(String profile, String id) async =>
      (await customSelect(
        'SELECT version FROM sync_versions WHERE profile_id=? AND record_id=?',
        variables: [Variable(profile), Variable(id)],
      ).getSingleOrNull())?.read<int>('version') ??
      0;
  Future<void> _version(String profile, RemoteRecord r) async {
    await customStatement(
      'INSERT INTO sync_versions VALUES(?,?,?) ON CONFLICT(profile_id,record_id) DO UPDATE SET version=excluded.version',
      [profile, r.record.id, r.version],
    );
  }

  Future<bool> _dirty(String profile, String id) async =>
      (await customSelect(
        'SELECT 1 FROM outbox o WHERE o.profile_id=? AND o.record_id=? AND NOT EXISTS(SELECT 1 FROM sync_acks a WHERE a.operation_id=o.operation_id) LIMIT 1',
        variables: [Variable(profile), Variable(id)],
      ).getSingleOrNull()) !=
      null;
  @override
  Future<int> pendingSyncCount(String profile) async => (await customSelect(
    'SELECT count(*) AS n FROM outbox o WHERE o.profile_id=? AND NOT EXISTS(SELECT 1 FROM sync_acks a WHERE a.operation_id=o.operation_id)',
    variables: [Variable(profile)],
  ).getSingle()).read<int>('n');
  @override
  Future<SyncCommand?> nextSyncCommand(String profile) => transaction(() async {
    final scope = await syncScope(profile);
    if (scope == null) throw const SyncFailure('connection');
    final row = await customSelect(
      '''SELECT o.* FROM outbox o WHERE o.profile_id=? AND NOT EXISTS(SELECT 1 FROM sync_acks a WHERE a.operation_id=o.operation_id) AND NOT EXISTS(SELECT 1 FROM sync_conflicts c WHERE c.profile_id=o.profile_id AND c.record_id=o.record_id) ORDER BY CASE WHEN o.record_id=o.profile_id THEN 0 ELSE 1 END,o.rowid LIMIT 1''',
      variables: [Variable(profile)],
    ).getSingleOrNull();
    if (row == null) return null;
    final operation = row.read<String>('operation_id');
    final attempted = await customSelect(
      'SELECT request FROM sync_attempts WHERE operation_id=?',
      variables: [Variable(operation)],
    ).getSingleOrNull();
    if (attempted != null) {
      return SyncCommand.fromJson(
        jsonDecode(attempted.read<String>('request')) as Map<String, dynamic>,
      );
    }
    final local =
        jsonDecode(row.read<String>('request')) as Map<String, dynamic>;
    final command = SyncCommand(
      operationId: operation,
      deviceId: scope.deviceId,
      baseVersion: await _remoteVersion(profile, row.read<String>('record_id')),
      payload: Map<String, dynamic>.from(local['payload'] as Map),
      deleted: local['delete'] as bool,
    );
    await customStatement('INSERT INTO sync_attempts VALUES(?,?)', [
      operation,
      jsonEncode(command.toJson()),
    ]);
    return command;
  });
  Future<void> _remember(String profile, RemoteRecord r) async {
    await customStatement(
      'INSERT OR IGNORE INTO sync_remote_history VALUES(?,?,?,?)',
      [profile, r.record.id, r.version, jsonEncode(r.toJson())],
    );
  }

  Future<void> _conflict(String profile, RemoteRecord r) async {
    final old = await customSelect(
      'SELECT remote FROM sync_conflicts WHERE profile_id=? AND record_id=?',
      variables: [Variable(profile), Variable(r.record.id)],
    ).getSingleOrNull();
    if (old != null &&
        RemoteRecord.fromJson(
              jsonDecode(old.read<String>('remote')) as Map<String, dynamic>,
            ).version >
            r.version) {
      return;
    }
    await customStatement(
      'INSERT INTO sync_conflicts VALUES(?,?,?) ON CONFLICT(profile_id,record_id) DO UPDATE SET remote=excluded.remote',
      [profile, r.record.id, jsonEncode(r.toJson())],
    );
  }

  @override
  Future<void> acceptSyncReply(
    String profile,
    SyncCommand command,
    SyncReply reply,
  ) => transaction(() async {
    final retired = await customSelect(
      'SELECT reason FROM sync_acks WHERE operation_id=?',
      variables: [Variable(command.operationId)],
    ).getSingleOrNull();
    if (retired?.read<String>('reason') == 'superseded') return;
    final stored = await customSelect(
      'SELECT request FROM sync_attempts WHERE operation_id=?',
      variables: [Variable(command.operationId)],
    ).getSingleOrNull();
    if (stored == null ||
        stored.read<String>('request') != jsonEncode(command.toJson()) ||
        reply.current.record.profileId != profile ||
        reply.current.record.id != command.record.id) {
      throw const SyncFailure('schema');
    }
    await _remember(profile, reply.current);
    if (!reply.applied) {
      await _conflict(profile, reply.current);
      return;
    }
    if (reply.current.deviceId != command.deviceId ||
        reply.current.operationId != command.operationId ||
        reply.current.version != command.baseVersion + 1 ||
        reply.current.deleted != command.deleted ||
        canonicalSyncJson(reply.current.payload) !=
            canonicalSyncJson(command.payload)) {
      throw const SyncFailure('schema');
    }
    await customStatement('INSERT OR IGNORE INTO sync_acks VALUES(?,?)', [
      command.operationId,
      'applied',
    ]);
    if (reply.current.version >
        await _remoteVersion(profile, command.record.id)) {
      await _version(profile, reply.current);
    }
  });
  Future<RecordEntry?> _local(String profile, String id) async {
    final row = await customSelect(
      'SELECT * FROM records WHERE profile_id=? AND id=?',
      variables: [Variable(profile), Variable(id)],
    ).getSingleOrNull();
    return row == null
        ? null
        : RecordEntry(
            decodeRecord(
              jsonDecode(row.read<String>('payload')) as Map<String, dynamic>,
            ),
            row.read<int>('revision'),
            deleted: row.read<int>('deleted') != 0,
          );
  }

  Future<void> _write(String profile, HealthRecord record, bool deleted) async {
    record.validate();
    if (record.profileId != profile || (deleted && record is MedicalProfile)) {
      throw const SyncFailure('schema');
    }
    final collision = await customSelect(
      'SELECT profile_id,kind FROM records WHERE id=?',
      variables: [Variable(record.id)],
    ).getSingleOrNull();
    if (collision != null &&
        (collision.read<String>('profile_id') != profile ||
            collision.read<String>('kind') != record.kind.name)) {
      throw const SyncFailure('scope');
    }
    final previous = await _local(profile, record.id),
        revision = (previous?.revision ?? 0) + 1,
        now = syncNow.toUtc().toIso8601String(),
        payload = jsonEncode(encodeRecord(record));
    await customStatement(
      '''INSERT INTO records VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,revision=excluded.revision,deleted=excluded.deleted,updated_at=excluded.updated_at''',
      [
        record.id,
        profile,
        record.kind.name,
        payload,
        revision,
        deleted ? 1 : 0,
        now,
      ],
    );
    await customStatement('INSERT INTO record_history VALUES(?,?,?,?,?,?)', [
      record.id,
      profile,
      revision,
      payload,
      deleted ? 1 : 0,
      now,
    ]);
  }

  @override
  Future<void> applySyncChangePage(String profile, SyncChangePage page) =>
      transaction(() async {
        final scope = await syncScope(profile);
        if (scope == null || scope.epoch != page.epoch) {
          throw const SyncFailure('server_changed');
        }
        if (page.cursor < scope.cursor ||
            (page.more && page.cursor == scope.cursor)) {
          throw const SyncFailure('schema');
        }
        var previous = scope.cursor;
        for (final remote in page.records) {
          if (remote.record.profileId != profile ||
              remote.sequence <= previous ||
              remote.sequence > page.cursor) {
            throw const SyncFailure('schema');
          }
          previous = remote.sequence;
          await _remember(profile, remote);
          if (remote.version <=
              await _remoteVersion(profile, remote.record.id)) {
            continue;
          }
          final own = remote.deviceId == scope.deviceId
              ? await customSelect(
                  'SELECT request FROM sync_attempts WHERE operation_id=?',
                  variables: [Variable(remote.operationId)],
                ).getSingleOrNull()
              : null;
          if (own != null) {
            await acceptSyncReply(
              profile,
              SyncCommand.fromJson(
                jsonDecode(own.read<String>('request')) as Map<String, dynamic>,
              ),
              SyncReply(true, remote),
            );
            continue;
          }
          if (await _dirty(profile, remote.record.id)) {
            await _conflict(profile, remote);
            continue;
          }
          await _write(profile, remote.record, remote.deleted);
          await _version(profile, remote);
        }
        if (page.records.isNotEmpty && previous != page.cursor) {
          throw const SyncFailure('schema');
        }
        if (page.records.isEmpty && page.cursor != scope.cursor) {
          throw const SyncFailure('schema');
        }
        await customStatement(
          'UPDATE sync_scopes SET cursor=? WHERE profile_id=?',
          [page.cursor, profile],
        );
      });
  @override
  Future<List<SyncConflict>> syncConflicts(String profile) async {
    final rows = await customSelect(
      'SELECT * FROM sync_conflicts WHERE profile_id=? ORDER BY record_id',
      variables: [Variable(profile)],
    ).get();
    final result = <SyncConflict>[];
    for (final row in rows) {
      final local = await _local(profile, row.read<String>('record_id'));
      if (local == null) throw const SyncFailure('schema');
      result.add(
        SyncConflict(
          local,
          RemoteRecord.fromJson(
            jsonDecode(row.read<String>('remote')) as Map<String, dynamic>,
          ),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> resolveSyncConflict(
    String profile,
    String recordId, {
    required bool keepLocal,
    required String operationId,
    required int localRevision,
    required int remoteVersion,
  }) => transaction(() async {
    final conflict = (await syncConflicts(profile))
        .where((c) => c.local.record.id == recordId)
        .firstOrNull;
    if (conflict == null ||
        conflict.local.revision != localRevision ||
        conflict.remote.version != remoteVersion) {
      throw const RecordConflict();
    }
    if (operationId.isEmpty) throw const InvalidRecord('operationId');
    await customStatement(
      "INSERT OR IGNORE INTO sync_acks SELECT operation_id,'superseded' FROM outbox WHERE profile_id=? AND record_id=?",
      [profile, recordId],
    );
    await _version(profile, conflict.remote);
    if (keepLocal) {
      final r = conflict.local;
      await _write(profile, r.record, r.deleted);
      final request = jsonEncode({
        'payload': encodeRecord(r.record),
        'expectedRevision': localRevision,
        'delete': r.deleted,
      });
      await customStatement('INSERT INTO outbox VALUES(?,?,?,?,?,?)', [
        operationId,
        profile,
        recordId,
        localRevision + 1,
        request,
        syncNow.toUtc().toIso8601String(),
      ]);
    } else {
      await _write(profile, conflict.remote.record, conflict.remote.deleted);
    }
    await customStatement(
      'DELETE FROM sync_conflicts WHERE profile_id=? AND record_id=?',
      [profile, recordId],
    );
  });
  @override
  Future<void> syncFailed(
    String profile,
    SyncFailure failure,
    DateTime now,
  ) async {
    final attempts = ((await syncScope(profile))?.attempts ?? 0) + 1;
    final retry = failure.retryable
        ? now
              .toUtc()
              .add(
                Duration(
                  seconds: math.min(300, 2 * (1 << math.min(attempts - 1, 8))),
                ),
              )
              .toIso8601String()
        : null;
    await customStatement(
      'UPDATE sync_scopes SET attempts=?,error=?,retry_at=? WHERE profile_id=?',
      [attempts, failure.code, retry, profile],
    );
  }

  @override
  Future<void> syncSucceeded(String profile, DateTime now) async {
    await customStatement(
      'UPDATE sync_scopes SET attempts=0,error=NULL,retry_at=NULL,last_success=? WHERE profile_id=?',
      [now.toUtc().toIso8601String(), profile],
    );
  }
}
