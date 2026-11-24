import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';

import 'model.dart';

/// PostgreSQL owns reservations, finalized metadata and the outgoing event.
final class DocumentsStore {
  DocumentsStore(this.db, this.objects, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final Pool db;
  final ObjectStorage objects;
  final DateTime Function() clock;

  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786204)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS documents_schema (id integer PRIMARY KEY CHECK(id=1), version integer NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO documents_schema VALUES (1,1) ON CONFLICT DO NOTHING',
    );
    if ((await tx.execute('SELECT version FROM documents_schema')).single[0] !=
        1) {
      throw StateError('Unsupported Documents schema');
    }
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS accounts (owner_id text PRIMARY KEY,
      quota_bytes bigint NOT NULL CHECK(quota_bytes>=0), used_bytes bigint NOT NULL DEFAULT 0 CHECK(used_bytes>=0),
      reserved_bytes bigint NOT NULL DEFAULT 0 CHECK(reserved_bytes>=0))''',
      '''CREATE TABLE IF NOT EXISTS profile_access (owner_id text REFERENCES accounts(owner_id),
      profile_id text NOT NULL, cloud_enabled boolean NOT NULL, PRIMARY KEY(owner_id,profile_id))''',
      '''CREATE TABLE IF NOT EXISTS uploads (owner_id text REFERENCES accounts(owner_id), original_id text,
      profile_id text NOT NULL, document_id text NOT NULL, metadata text NOT NULL,
      state text NOT NULL CHECK(state IN ('reserved','staged','ready','expired')),
      expires_at timestamptz NOT NULL, staging_cleaned boolean NOT NULL DEFAULT false,
      PRIMARY KEY(owner_id, original_id), UNIQUE(owner_id,document_id))''',
      '''CREATE TABLE IF NOT EXISTS document_outbox (event_id text PRIMARY KEY,
      event_type text NOT NULL, payload text NOT NULL, created_at timestamptz NOT NULL)''',
    ]) {
      await tx.execute(sql);
    }
  });

  Future<void> grant(
    String owner,
    String profile,
    int quota, {
    bool enabled = true,
  }) => db.runTx((tx) async {
    checkId(owner);
    checkId(profile);
    await tx.execute(
      Sql.named(
        'INSERT INTO accounts(owner_id,quota_bytes) VALUES (@o,@q) ON CONFLICT DO NOTHING',
      ),
      parameters: {'o': owner, 'q': quota},
    );
    await tx.execute(
      Sql.named(
        'INSERT INTO profile_access VALUES (@o,@p,@e) ON CONFLICT DO NOTHING',
      ),
      parameters: {'o': owner, 'p': profile, 'e': enabled},
    );
  });

  Future<void> _access(
    Session tx,
    String owner,
    String profile, {
    bool upload = true,
  }) async {
    final rows = await tx.execute(
      Sql.named(
        'SELECT cloud_enabled FROM profile_access WHERE owner_id=@o AND profile_id=@p',
      ),
      parameters: {'o': owner, 'p': profile},
    );
    if (rows.isEmpty) throw const ApiError(404, 'not_found');
    if (upload && rows.single[0] != true) {
      throw const ApiError(403, 'cloud_disabled');
    }
  }

  Future<Map<String, dynamic>> _session(
    Session tx,
    String owner,
    String profile,
    String original,
  ) async {
    await _access(tx, owner, profile);
    await tx.execute(
      Sql.named('SELECT owner_id FROM accounts WHERE owner_id=@o FOR UPDATE'),
      parameters: {'o': owner},
    );
    final rows = await tx.execute(
      Sql.named(
        'SELECT * FROM uploads WHERE owner_id=@o AND profile_id=@p AND original_id=@i FOR UPDATE',
      ),
      parameters: {'o': owner, 'p': profile, 'i': original},
    );
    if (rows.isEmpty) throw const ApiError(404, 'not_found');
    return rows.single.toColumnMap();
  }

  String stagingKey(String owner, String original) =>
      'staging/$owner/$original';
  String originalKey(String owner, String original) =>
      'originals/$owner/$original';
  UploadMetadata metadata(Map<String, dynamic> row) => UploadMetadata(
    jsonDecode(row['metadata'] as String) as Map<String, dynamic>,
  );
  Map<String, Object> _receipt(UploadMetadata m, String state) => {
    ...m.toJson(),
    'schemaVersion': 1,
    'state': state,
  };

  Future<Map<String, Object>> reserve(
    String owner,
    String profile,
    UploadMetadata m,
  ) => db.runTx((tx) async {
    await _access(tx, owner, profile);
    final account = (await tx.execute(
      Sql.named('SELECT * FROM accounts WHERE owner_id=@o FOR UPDATE'),
      parameters: {'o': owner},
    )).single.toColumnMap();
    final rows = await tx.execute(
      Sql.named('SELECT * FROM uploads WHERE owner_id=@o AND original_id=@i'),
      parameters: {'o': owner, 'i': m.originalId},
    );
    if (rows.isNotEmpty) {
      final old = rows.single.toColumnMap();
      if (old['profile_id'] != profile ||
          old['metadata'] != jsonEncode(m.toJson())) {
        throw const ApiError(409, 'operation_mismatch');
      }
      if (old['state'] != 'expired') return _receipt(m, old['state'] as String);
    }
    if ((account['used_bytes'] as int) +
            (account['reserved_bytes'] as int) +
            m.size >
        (account['quota_bytes'] as int)) {
      throw const ApiError(409, 'quota_exceeded');
    }
    await tx.execute(
      Sql.named(
        'UPDATE accounts SET reserved_bytes=reserved_bytes+@n WHERE owner_id=@o',
      ),
      parameters: {'o': owner, 'n': m.size},
    );
    await tx.execute(
      Sql.named(
        '''INSERT INTO uploads(owner_id,original_id,profile_id,document_id,metadata,state,expires_at) VALUES (@o,@i,@p,@d,@m,'reserved',@t)
      ON CONFLICT(owner_id,original_id) DO UPDATE SET state='reserved', expires_at=EXCLUDED.expires_at, staging_cleaned=false''',
      ),
      parameters: {
        'o': owner,
        'i': m.originalId,
        'p': profile,
        'd': m.documentId,
        'm': jsonEncode(m.toJson()),
        't': clock().toUtc().add(const Duration(hours: 24)),
      },
    );
    return _receipt(m, 'reserved');
  });

  Future<void> stage(
    String owner,
    String profile,
    String original,
    Uint8List bytes,
  ) => db.runTx((tx) async {
    final row = await _session(tx, owner, profile, original);
    final m = metadata(row);
    m.verify(bytes);
    if (row['state'] == 'ready') return;
    if (row['state'] == 'expired' ||
        (row['expires_at'] as DateTime).isBefore(clock())) {
      throw const ApiError(410, 'upload_expired');
    }
    await objects.put(stagingKey(owner, original), bytes);
    await tx.execute(
      Sql.named(
        "UPDATE uploads SET state='staged' WHERE owner_id=@o AND original_id=@i",
      ),
      parameters: {'o': owner, 'i': original},
    );
  });

  Future<void> _ready(
    Session tx,
    String owner,
    String profile,
    UploadMetadata m,
  ) async {
    await tx.execute(
      Sql.named(
        "UPDATE uploads SET state='ready' WHERE owner_id=@o AND original_id=@i",
      ),
      parameters: {'o': owner, 'i': m.originalId},
    );
    await tx.execute(
      Sql.named(
        'UPDATE accounts SET used_bytes=used_bytes+@n, reserved_bytes=reserved_bytes-@n WHERE owner_id=@o',
      ),
      parameters: {'o': owner, 'n': m.size},
    );
    await tx.execute(
      Sql.named(
        "INSERT INTO document_outbox VALUES (@id,'DocumentReady',@j,@t) ON CONFLICT DO NOTHING",
      ),
      parameters: {
        'id': '$owner:${m.originalId}',
        'j': jsonEncode({
          'schemaVersion': 1,
          'ownerId': owner,
          'profileId': profile,
          'documentId': m.documentId,
          'originalId': m.originalId,
        }),
        't': clock().toUtc(),
      },
    );
  }

  Future<Map<String, Object>> finalize(
    String owner,
    String profile,
    String original,
  ) => db.runTx((tx) async {
    final row = await _session(tx, owner, profile, original);
    final m = metadata(row);
    if (row['state'] == 'ready') return _receipt(m, 'ready');
    if (row['state'] == 'expired') throw const ApiError(410, 'upload_expired');
    final key = originalKey(owner, original);
    var published = await objects.get(key);
    if (published == null) {
      if ((row['expires_at'] as DateTime).isBefore(clock())) {
        throw const ApiError(410, 'upload_expired');
      }
      final staged = await objects.get(stagingKey(owner, original));
      if (staged == null) throw const ApiError(409, 'not_staged');
      m.verify(staged);
      // Publish the verified snapshot, never a live mutable staging locator.
      await objects.put(key, staged);
      published = await objects.get(key);
    }
    if (published == null) throw const ApiError(502, 'object_unavailable');
    m.verify(published);
    await _ready(tx, owner, profile, m);
    return _receipt(m, 'ready');
  });

  Future<(UploadMetadata, Uint8List)> download(
    String owner,
    String profile,
    String original,
  ) async {
    final m = await db.run((tx) async {
      await _access(tx, owner, profile, upload: false);
      final rows = await tx.execute(
        Sql.named(
          "SELECT metadata FROM uploads WHERE owner_id=@o AND profile_id=@p AND original_id=@i AND state='ready'",
        ),
        parameters: {'o': owner, 'p': profile, 'i': original},
      );
      if (rows.isEmpty) throw const ApiError(404, 'not_found');
      return UploadMetadata(
        jsonDecode(rows.single[0] as String) as Map<String, dynamic>,
      );
    });
    final bytes = await objects.get(originalKey(owner, original));
    if (bytes == null) throw const ApiError(502, 'object_unavailable');
    m.verify(bytes);
    return (m, bytes);
  }

  Future<void> cleanup() async {
    final rows = await db.execute(
      Sql.named(
        "SELECT owner_id,original_id FROM uploads WHERE state IN ('reserved','staged') AND expires_at<@now LIMIT 100",
      ),
      parameters: {'now': clock().toUtc()},
    );
    for (final row in rows) {
      await db.runTx((tx) async {
        final owner = row[0] as String, original = row[1] as String;
        await tx.execute(
          Sql.named(
            'SELECT owner_id FROM accounts WHERE owner_id=@o FOR UPDATE',
          ),
          parameters: {'o': owner},
        );
        final sessions = await tx.execute(
          Sql.named(
            'SELECT * FROM uploads WHERE owner_id=@o AND original_id=@i FOR UPDATE',
          ),
          parameters: {'o': owner, 'i': original},
        );
        final session = sessions.single.toColumnMap();
        if (!['reserved', 'staged'].contains(session['state']) ||
            !(session['expires_at'] as DateTime).isBefore(clock())) {
          return;
        }
        final m = metadata(session);
        final published = await objects.get(originalKey(owner, original));
        if (published != null) {
          m.verify(published);
          await _ready(tx, owner, session['profile_id'] as String, m);
        } else {
          await objects.delete(stagingKey(owner, original));
          await tx.execute(
            Sql.named(
              "UPDATE uploads SET state='expired' WHERE owner_id=@o AND original_id=@i",
            ),
            parameters: {'o': owner, 'i': original},
          );
          await tx.execute(
            Sql.named(
              'UPDATE accounts SET reserved_bytes=reserved_bytes-@n WHERE owner_id=@o',
            ),
            parameters: {'o': owner, 'n': m.size},
          );
        }
      });
    }
    // Staging is disposable only after the metadata transaction committed.
    final ready = await db.execute(
      "SELECT owner_id,original_id FROM uploads WHERE state='ready' AND NOT staging_cleaned LIMIT 100",
    );
    for (final row in ready) {
      await objects.delete(stagingKey(row[0] as String, row[1] as String));
      await db.execute(
        Sql.named(
          'UPDATE uploads SET staging_cleaned=true WHERE owner_id=@o AND original_id=@i',
        ),
        parameters: {'o': row[0], 'i': row[1]},
      );
    }
  }
}
