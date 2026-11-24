import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

class ApiError implements Exception {
  const ApiError(this.status, this.code);
  final int status;
  final String code;
}

class TokenIdentity {
  const TokenIdentity(this.ownerId, this.hash);
  final String ownerId, hash;
}

String _nonce() => List.generate(
  24,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

class RecordsService {
  RecordsService(this.db, this.identities);
  final Pool db;
  final List<TokenIdentity> identities;
  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786207)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS records_schema(id int PRIMARY KEY CHECK(id=1),version int NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO records_schema VALUES(1,1) ON CONFLICT DO NOTHING',
    );
    if ((await tx.execute('SELECT version FROM records_schema')).single[0] !=
        1) {
      throw StateError('Unsupported records schema');
    }
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS scopes(owner_id text,profile_id text,epoch text NOT NULL,head bigint NOT NULL DEFAULT 0,can_write boolean NOT NULL DEFAULT true,PRIMARY KEY(owner_id,profile_id))''',
      '''CREATE TABLE IF NOT EXISTS records(owner_id text,profile_id text,record_id text,kind text NOT NULL,payload text NOT NULL,version bigint NOT NULL,deleted boolean NOT NULL,sequence bigint NOT NULL,PRIMARY KEY(owner_id,profile_id,record_id))''',
      '''CREATE TABLE IF NOT EXISTS changes(owner_id text,profile_id text,sequence bigint,payload text NOT NULL,PRIMARY KEY(owner_id,profile_id,sequence))''',
      '''CREATE TABLE IF NOT EXISTS operations(owner_id text,device_id text,operation_id text,request text NOT NULL,response text NOT NULL,PRIMARY KEY(owner_id,device_id,operation_id))''',
      '''CREATE TABLE IF NOT EXISTS record_outbox(event_id text PRIMARY KEY,payload text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
    ]) {
      await tx.execute(sql);
    }
  });
  Future<void> grant(String owner, String profile) => db.execute(
    Sql.named(
      'INSERT INTO scopes(owner_id,profile_id,epoch) VALUES(@o,@p,@e) ON CONFLICT DO NOTHING',
    ),
    parameters: {'o': owner, 'p': profile, 'e': _nonce()},
  );
  String _owner(Request req) {
    final token = req.headers['authorization'] ?? '';
    if (!token.startsWith('Bearer ') || token.length > 2048) {
      throw const ApiError(401, 'unauthorized');
    }
    final digest = sha256.convert(utf8.encode(token.substring(7))).toString();
    for (final i in identities) {
      var diff = digest.length ^ i.hash.length;
      for (var n = 0; n < digest.length && n < i.hash.length; n++) {
        diff |= digest.codeUnitAt(n) ^ i.hash.codeUnitAt(n);
      }
      if (diff == 0) return i.ownerId;
    }
    throw const ApiError(401, 'unauthorized');
  }

  Future<Map<String, dynamic>> _scope(
    Session tx,
    String owner,
    String profile, {
    bool lock = false,
  }) async {
    final rows = await tx.execute(
      Sql.named(
        'SELECT * FROM scopes WHERE owner_id=@o AND profile_id=@p${lock ? ' FOR UPDATE' : ''}',
      ),
      parameters: {'o': owner, 'p': profile},
    );
    if (rows.isEmpty) throw const ApiError(404, 'not_found');
    return rows.single.toColumnMap();
  }

  Response _json(int status, Map<String, Object?> j) => Response(
    status,
    body: jsonEncode(j),
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  );
  Future<Map<String, dynamic>> _body(Request req) async {
    final bytes = <int>[];
    await for (final chunk in req.read().timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > 262144) {
        throw const ApiError(413, 'too_large');
      }
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  RemoteRecord _remote(
    Map<String, dynamic> row, {
    String device = '',
    String op = '',
  }) => RemoteRecord(
    payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
    version: row['version'] as int,
    deleted: row['deleted'] as bool,
    sequence: row['sequence'] as int,
    deviceId: device,
    operationId: op,
  );
  Future<Response> call(Request req) async {
    try {
      if (req.method == 'GET' && req.url.path == 'health') {
        return _json(200, {'status': 'ok'});
      }
      final owner = _owner(req), p = req.url.pathSegments;
      if (p.length != 4 ||
          p[0] != 'v1' ||
          p[1] != 'profiles' ||
          !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(p[2])) {
        throw const ApiError(404, 'not_found');
      }
      final profile = p[2];
      if (p[3] == 'sync-access' && req.method == 'GET') {
        final scope = await db.run((tx) => _scope(tx, owner, profile));
        return _json(200, {
          'schemaVersion': 1,
          'ownerId': owner,
          'profileId': profile,
          'epoch': scope['epoch'],
          'canWrite': scope['can_write'],
        });
      }
      if (p[3] == 'sync-changes' && req.method == 'GET') {
        final scope = await db.run((tx) => _scope(tx, owner, profile));
        if (req.url.queryParameters['epoch'] != scope['epoch']) {
          throw const ApiError(409, 'server_changed');
        }
        final cursor =
                int.tryParse(req.url.queryParameters['cursor'] ?? '') ?? -1,
            head = scope['head'] as int;
        if (cursor < 0 || cursor > head) throw const ApiError(409, 'cursor');
        final rows = await db.execute(
          Sql.named(
            'SELECT sequence,payload FROM changes WHERE owner_id=@o AND profile_id=@p AND sequence>@c AND sequence<=@h ORDER BY sequence LIMIT 100',
          ),
          parameters: {'o': owner, 'p': profile, 'c': cursor, 'h': head},
        );
        var next = cursor, size = 0;
        final records = <Object?>[];
        for (final row in rows) {
          final payload = row[1] as String;
          final bytes = utf8.encode(payload).length;
          if (size + bytes > 3 * 1024 * 1024) break;
          records.add(jsonDecode(payload));
          size += bytes;
          next = row[0] as int;
        }
        return _json(200, {
          'schemaVersion': 1,
          'epoch': scope['epoch'],
          'cursor': next,
          'more': next < head,
          'records': records,
        });
      }
      if (p[3] == 'sync-operations' && req.method == 'POST') {
        final body = await _body(req), command = SyncCommand.fromJson(body);
        final record = command.record;
        record.validate();
        if (record.profileId != profile) throw const ApiError(404, 'not_found');
        if (!RegExp(r'^[A-Za-z0-9_:-]{1,400}$').hasMatch(command.operationId) ||
            !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(command.deviceId) ||
            !RegExp(r'^[A-Za-z0-9_-]{1,200}$').hasMatch(record.id) ||
            command.baseVersion < 0 ||
            canonicalSyncJson(encodeRecord(record)) !=
                canonicalSyncJson(command.payload) ||
            (record is MedicalProfile && command.deleted)) {
          throw const ApiError(400, 'schema');
        }
        final fingerprint = canonicalSyncJson({
          'epoch': body['epoch'],
          'command': command.toJson(),
        });
        final response = await db.runTx((tx) async {
          final scope = await _scope(tx, owner, profile, lock: true);
          if (scope['epoch'] != body['epoch']) {
            throw const ApiError(409, 'server_changed');
          }
          if (scope['can_write'] != true) throw const ApiError(403, 'access');
          // Profile lock serializes sequence assignment and commit order, including replays.
          final previous = await tx.execute(
            Sql.named(
              'SELECT request,response FROM operations WHERE owner_id=@o AND device_id=@d AND operation_id=@i',
            ),
            parameters: {
              'o': owner,
              'd': command.deviceId,
              'i': command.operationId,
            },
          );
          if (previous.isNotEmpty) {
            if (previous.single[0] != fingerprint) {
              throw const ApiError(409, 'operation_mismatch');
            }
            return jsonDecode(previous.single[1] as String)
                as Map<String, dynamic>;
          }
          final rows = await tx.execute(
            Sql.named(
              'SELECT * FROM records WHERE owner_id=@o AND profile_id=@p AND record_id=@r',
            ),
            parameters: {'o': owner, 'p': profile, 'r': record.id},
          );
          final old = rows.isEmpty ? null : rows.single.toColumnMap();
          Map<String, Object?> result;
          if ((old?['version'] ?? 0) != command.baseVersion) {
            if (old == null) throw const ApiError(409, 'missing_base');
            result = {
              'schemaVersion': 1,
              'applied': false,
              'current': _remote(old).toJson(),
            };
          } else {
            if (old != null && old['kind'] != record.kind.name) {
              throw const ApiError(409, 'kind');
            }
            if (old == null && command.deleted) {
              throw const ApiError(400, 'schema');
            }
            if (record is! MedicalProfile) {
              final parent = await tx.execute(
                Sql.named(
                  "SELECT 1 FROM records WHERE owner_id=@o AND profile_id=@p AND record_id=@p AND kind='profile' AND deleted=false",
                ),
                parameters: {'o': owner, 'p': profile},
              );
              if (parent.isEmpty) throw const ApiError(409, 'profile_required');
            }
            final seq = (scope['head'] as int) + 1,
                version = command.baseVersion + 1;
            final remote = RemoteRecord(
              payload: command.payload,
              version: version,
              deleted: command.deleted,
              sequence: seq,
              deviceId: command.deviceId,
              operationId: command.operationId,
            );
            await tx.execute(
              Sql.named(
                'INSERT INTO records VALUES(@o,@p,@r,@k,@j,@v,@x,@s) ON CONFLICT(owner_id,profile_id,record_id) DO UPDATE SET payload=excluded.payload,version=excluded.version,deleted=excluded.deleted,sequence=excluded.sequence',
              ),
              parameters: {
                'o': owner,
                'p': profile,
                'r': record.id,
                'k': record.kind.name,
                'j': jsonEncode(command.payload),
                'v': version,
                'x': command.deleted,
                's': seq,
              },
            );
            await tx.execute(
              Sql.named(
                'UPDATE scopes SET head=@s WHERE owner_id=@o AND profile_id=@p',
              ),
              parameters: {'o': owner, 'p': profile, 's': seq},
            );
            await tx.execute(
              Sql.named('INSERT INTO changes VALUES(@o,@p,@s,@j)'),
              parameters: {
                'o': owner,
                'p': profile,
                's': seq,
                'j': jsonEncode(remote.toJson()),
              },
            );
            await tx.execute(
              Sql.named(
                'INSERT INTO record_outbox(event_id,payload) VALUES(@i,@j)',
              ),
              parameters: {
                'i': '$owner:$profile:$seq',
                'j': jsonEncode({
                  'schemaVersion': 1,
                  'type': 'RecordChanged',
                  'profileId': profile,
                  'recordId': record.id,
                  'version': version,
                  'deleted': command.deleted,
                }),
              },
            );
            result = {
              'schemaVersion': 1,
              'applied': true,
              'current': remote.toJson(),
            };
          }
          await tx.execute(
            Sql.named('INSERT INTO operations VALUES(@o,@d,@i,@q,@r)'),
            parameters: {
              'o': owner,
              'd': command.deviceId,
              'i': command.operationId,
              'q': fingerprint,
              'r': jsonEncode(result),
            },
          );
          return result;
        });
        return _json(200, response);
      }
      throw const ApiError(404, 'not_found');
    } on ApiError catch (e) {
      return _json(e.status, {'error': e.code});
    } on FormatException {
      return _json(400, {'error': 'schema'});
    } on TypeError {
      return _json(400, {'error': 'schema'});
    } on InvalidRecord {
      return _json(400, {'error': 'invalid_record'});
    } on ArgumentError {
      return _json(400, {'error': 'schema'});
    } catch (_) {
      return _json(503, {'error': 'unavailable'});
    }
  }
}
