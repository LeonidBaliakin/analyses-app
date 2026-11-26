import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_access/cloud_access.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

class PolicyError implements Exception {
  const PolicyError(this.status, this.code);
  final int status;
  final String code;
}

class EntitlementsService {
  EntitlementsService(
    this.db, {
    required this.serviceKey,
    required this.adminKey,
    this.defaultRecordLimit = 10000,
    this.defaultStorageBytes = 1073741824,
    this.defaultMonthlyJobs = 100,
  });
  final Pool db;
  final String serviceKey, adminKey;
  final int defaultRecordLimit, defaultStorageBytes, defaultMonthlyJobs;
  bool _key(String? value, String expected) {
    final a = sha256.convert(utf8.encode(value ?? '')).bytes,
        b = sha256.convert(utf8.encode(expected)).bytes;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return expected.isNotEmpty && diff == 0;
  }

  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786209)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS entitlement_schema(id int PRIMARY KEY CHECK(id=1),version int NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO entitlement_schema VALUES(1,1) ON CONFLICT DO NOTHING',
    );
    if ((await tx.execute('SELECT version FROM entitlement_schema'))
            .single[0] !=
        1) {
      throw StateError('Unsupported entitlements schema');
    }
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS policies(owner_id text PRIMARY KEY,revision bigint NOT NULL,payload text NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS grants(operation_id text PRIMARY KEY,request text NOT NULL,response text NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS policy_outbox(event_id text PRIMARY KEY,payload text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
    ]) {
      await tx.execute(sql);
    }
  });
  Future<Map<String, dynamic>> _current(Session tx, String owner) async {
    final initial = CloudPolicy(
      ownerId: owner,
      revision: 1,
      syncEnabled: true,
      storageEnabled: true,
      processingEnabled: true,
      recordLimit: defaultRecordLimit,
      storageLimitBytes: defaultStorageBytes,
      processingMonthlyLimit: defaultMonthlyJobs,
    );
    await tx.execute(
      Sql.named('INSERT INTO policies VALUES(@o,1,@j) ON CONFLICT DO NOTHING'),
      parameters: {'o': owner, 'j': jsonEncode(initial.toJson())},
    );
    final rows = await tx.execute(
      Sql.named(
        'SELECT payload,CURRENT_TIMESTAMP AS now FROM policies WHERE owner_id=@o FOR UPDATE',
      ),
      parameters: {'o': owner},
    );
    final j = jsonDecode(rows.single[0] as String) as Map<String, dynamic>;
    final until = j['validUntil'] == null
        ? null
        : DateTime.parse(j['validUntil'] as String);
    j['active'] = until == null || until.isAfter(rows.single[1] as DateTime);
    return j;
  }

  Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json', 'cache-control': 'no-store'},
  );
  Future<Response> call(Request req) async {
    try {
      if (req.method == 'GET' && req.url.path == 'health') {
        await db.execute('SELECT 1');
        return _json(200, {'status': 'ok'});
      }
      final p = req.url.pathSegments;
      if (p.length != 3 ||
          p[0] != 'internal' ||
          p[1] != 'policies' ||
          !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(p[2])) {
        throw const PolicyError(404, 'not_found');
      }
      final owner = p[2];
      if (req.method == 'GET') {
        if (!_key(req.headers['x-cloud-service-key'], serviceKey)) {
          throw const PolicyError(401, 'unauthorized');
        }
        return _json(200, await db.runTx((tx) => _current(tx, owner)));
      }
      if (req.method != 'PUT') throw const PolicyError(404, 'not_found');
      if (!_key(req.headers['x-cloud-admin-key'], adminKey)) {
        throw const PolicyError(401, 'unauthorized');
      }
      final b = <int>[];
      await for (final chunk in req.read().timeout(
        const Duration(seconds: 10),
      )) {
        if (b.length + chunk.length > 16384) {
          throw const PolicyError(413, 'too_large');
        }
        b.addAll(chunk);
      }
      final j = jsonDecode(utf8.decode(b)) as Map<String, dynamic>,
          id = j['operationId'] as String,
          base = j['baseRevision'] as int;
      if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id) || base < 1) {
        throw const PolicyError(400, 'schema');
      }
      final next = CloudPolicy.fromJson({
        ...Map<String, dynamic>.from(j['policy'] as Map),
        'schemaVersion': 1,
        'ownerId': owner,
        'revision': base + 1,
        'active': true,
      });
      final fingerprint = jsonEncode({
        'ownerId': owner,
        'baseRevision': base,
        'policy': next.toJson(),
      });
      return _json(
        200,
        await db.runTx((tx) async {
          // Serialize grant operation IDs across owners as well as owner revisions.
          await tx.execute(
            Sql.named('SELECT pg_advisory_xact_lock(hashtext(@i))'),
            parameters: {'i': id},
          );
          final current = await _current(tx, owner);
          final old = await tx.execute(
            Sql.named(
              'SELECT request,response FROM grants WHERE operation_id=@i',
            ),
            parameters: {'i': id},
          );
          if (old.isNotEmpty) {
            if (old.single[0] != fingerprint) {
              throw const PolicyError(409, 'operation_mismatch');
            }
            return jsonDecode(old.single[1] as String) as Map<String, dynamic>;
          }
          if (current['revision'] != base) {
            throw const PolicyError(409, 'revision_conflict');
          }
          await tx.execute(
            Sql.named(
              'UPDATE policies SET revision=@r,payload=@j WHERE owner_id=@o',
            ),
            parameters: {
              'r': next.revision,
              'j': jsonEncode(next.toJson()),
              'o': owner,
            },
          );
          final result = await _current(tx, owner);
          await tx.execute(
            Sql.named('INSERT INTO grants VALUES(@i,@q,@r)'),
            parameters: {'i': id, 'q': fingerprint, 'r': jsonEncode(result)},
          );
          await tx.execute(
            Sql.named(
              'INSERT INTO policy_outbox(event_id,payload) VALUES(@i,@j)',
            ),
            parameters: {
              'i': id,
              'j': jsonEncode({
                'schemaVersion': 1,
                'type': 'CloudPolicyChanged',
                'ownerId': owner,
                'revision': next.revision,
              }),
            },
          );
          return result;
        }),
      );
    } on PolicyError catch (e) {
      return _json(e.status, {'error': e.code});
    } on FormatException {
      return _json(400, {'error': 'schema'});
    } on TypeError {
      return _json(400, {'error': 'schema'});
    } catch (_) {
      return _json(503, {'error': 'unavailable'});
    }
  }
}
