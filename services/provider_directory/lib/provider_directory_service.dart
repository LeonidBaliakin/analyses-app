import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import 'src/import.dart';
export 'src/import.dart';

class ApiError implements Exception {
  const ApiError(this.status, this.code);
  final int status;
  final String code;
}

String nonce() => List.generate(
  24,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

class DirectoryService {
  DirectoryService(
    this.db, {
    required this.adminKey,
    required this.sourceKeys,
    this.allowedOrigins = const [],
  });
  final Pool db;
  final String adminKey;
  final Map<String, String> sourceKeys;
  final List<String> allowedOrigins;

  Future<void> migrate(List<Json> sources, Json seed) => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786217)');
    for (final sql in [
      'CREATE TABLE IF NOT EXISTS directory_schema(id int PRIMARY KEY CHECK(id=1),version int NOT NULL)',
      'INSERT INTO directory_schema VALUES(1,1) ON CONFLICT DO NOTHING',
      '''CREATE TABLE IF NOT EXISTS sources(id text PRIMARY KEY,config text NOT NULL,enabled boolean NOT NULL,interval_seconds int NOT NULL CHECK(interval_seconds>=3600),next_run timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,active_job text,last_success timestamptz,last_error text)''',
      '''CREATE TABLE IF NOT EXISTS jobs(id text PRIMARY KEY,source_id text NOT NULL REFERENCES sources(id),status text NOT NULL,attempt int NOT NULL,lease text NOT NULL,lease_until timestamptz NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,finished_at timestamptz,error text,receipt text,summary text)''',
      '''CREATE INDEX IF NOT EXISTS jobs_source_time ON jobs(source_id,created_at DESC)''',
      '''CREATE TABLE IF NOT EXISTS catalog(id int PRIMARY KEY CHECK(id=1),payload text NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS source_items(source_id text PRIMARY KEY REFERENCES sources(id),payload text NOT NULL,updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE IF NOT EXISTS directory_outbox(event_id text PRIMARY KEY,payload text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
    ]) {
      await tx.execute(sql);
    }
    if ((await tx.execute('SELECT version FROM directory_schema')).single[0] !=
        1) {
      throw StateError('Unsupported directory schema');
    }
    for (final s in sources) {
      if (!sourceKeys.containsKey(s['id'])) {
        throw StateError('Missing connector key');
      }
      await tx.execute(
        Sql.named(
          '''INSERT INTO sources(id,config,enabled,interval_seconds) VALUES(@id,@c,@e,@i) ON CONFLICT(id) DO UPDATE SET config=excluded.config''',
        ),
        parameters: {
          'id': s['id'],
          'c': jsonEncode(s),
          'e': s['enabled'],
          'i': s['intervalSeconds'],
        },
      );
    }
    await tx.execute(
      Sql.named('INSERT INTO catalog VALUES(1,@j) ON CONFLICT DO NOTHING'),
      parameters: {'j': jsonEncode(seed)},
    );
    final payload =
        (await tx.execute('SELECT payload FROM catalog WHERE id=1 FOR UPDATE'))
                .single[0]
            as String;
    final previous = jsonDecode(payload) as Json;
    final scoped = constrainInvitroCoverage(previous);
    if (!identical(scoped, previous)) {
      scoped['publishedAt'] =
          ((await tx.execute('SELECT CURRENT_TIMESTAMP')).single[0] as DateTime)
              .toUtc()
              .toIso8601String();
      await tx.execute(
        Sql.named('UPDATE catalog SET payload=@j WHERE id=1'),
        parameters: {'j': jsonEncode(scoped)},
      );
      await tx.execute(
        Sql.named(
          'INSERT INTO directory_outbox(event_id,payload) VALUES(@id,@j) ON CONFLICT DO NOTHING',
        ),
        parameters: {
          'id': scoped['version'],
          'j': jsonEncode({
            'schemaVersion': 1,
            'type': 'DirectoryPublished',
            'version': scoped['version'],
            'reason': 'pilot_coverage_review',
          }),
        },
      );
    }
  });

  void _authorize(Request req, String key) {
    final actual = req.headers['authorization'] ?? '';
    final expected = 'Bearer $key';
    var difference = actual.length ^ expected.length;
    for (var i = 0; i < actual.length && i < expected.length; i++) {
      difference |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    if (difference != 0) throw const ApiError(401, 'unauthorized');
  }

  Future<Json> _body(Request req) async {
    final bytes = <int>[];
    await for (final chunk in req.read().timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > 16 * 1024 * 1024) {
        throw const ApiError(413, 'too_large');
      }
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes)) as Json;
  }

  Future<Json> _source(Session tx, String id) async {
    final rows = await tx.execute(
      Sql.named('SELECT * FROM sources WHERE id=@s FOR UPDATE'),
      parameters: {'s': id},
    );
    if (rows.isEmpty) throw const ApiError(404, 'not_found');
    return rows.single.toColumnMap();
  }

  Future<Object?> claim(String source) => db.runTx((tx) async {
    final s = await _source(tx, source);
    final now =
        (await tx.execute('SELECT CURRENT_TIMESTAMP')).single[0] as DateTime;
    if (s['enabled'] != true) return null;
    Json? job;
    if (s['active_job'] != null) {
      job = (await tx.execute(
        Sql.named('SELECT * FROM jobs WHERE id=@j FOR UPDATE'),
        parameters: {'j': s['active_job']},
      )).single.toColumnMap();
      if ((job['lease_until'] as DateTime).isAfter(now)) return null;
      if ((job['attempt'] as int) >= 3) {
        await _finish(
          tx,
          s,
          job['id'] as String,
          'failed',
          error: 'lease_expired',
        );
        return null;
      }
    } else if ((s['next_run'] as DateTime).isAfter(now)) {
      return null;
    }
    final id = job?['id'] as String? ?? '$source-${nonce()}', lease = nonce();
    await tx.execute(
      Sql.named(
        '''INSERT INTO jobs(id,source_id,status,attempt,lease,lease_until) VALUES(@j,@s,'running',1,@l,CURRENT_TIMESTAMP+interval '120 seconds') ON CONFLICT(id) DO UPDATE SET attempt=jobs.attempt+1,lease=excluded.lease,lease_until=excluded.lease_until''',
      ),
      parameters: {'j': id, 's': source, 'l': lease},
    );
    await tx.execute(
      Sql.named('UPDATE sources SET active_job=@j WHERE id=@s'),
      parameters: {'j': id, 's': source},
    );
    return {
      'schemaVersion': 1,
      'jobId': id,
      'lease': lease,
      'config': jsonDecode(s['config'] as String),
    };
  });

  Future<void> _finish(
    Session tx,
    Json s,
    String job,
    String status, {
    String? error,
    String? receipt,
    Json? summary,
  }) async {
    await tx.execute(
      Sql.named(
        '''UPDATE jobs SET status=@t,finished_at=CURRENT_TIMESTAMP,error=@e,receipt=@r,summary=@u WHERE id=@j''',
      ),
      parameters: {
        't': status,
        'e': error,
        'r': receipt,
        'j': job,
        'u': summary == null ? null : jsonEncode(summary),
      },
    );
    await tx.execute(
      Sql.named(
        '''UPDATE sources SET active_job=NULL,next_run=CURRENT_TIMESTAMP+make_interval(secs=>@i),last_success=CASE WHEN @ok THEN CURRENT_TIMESTAMP ELSE last_success END,last_error=@e WHERE id=@s''',
      ),
      parameters: {
        's': s['id'],
        'i': status == 'succeeded' && error == null
            ? s['interval_seconds']
            : 3600,
        'ok': status == 'succeeded',
        'e': error,
      },
    );
  }

  Future<Json> result(String source, String jobId, Json body) => db.runTx((
    tx,
  ) async {
    final s = await _source(tx, source);
    final rows = await tx.execute(
      Sql.named('SELECT * FROM jobs WHERE id=@j AND source_id=@s FOR UPDATE'),
      parameters: {'j': jobId, 's': source},
    );
    if (rows.isEmpty) throw const ApiError(404, 'not_found');
    final j = rows.single.toColumnMap(), digest = fingerprint(body['result']);
    if (j['status'] == 'succeeded') {
      if (j['receipt'] != digest) throw const ApiError(409, 'result_mismatch');
      return jsonDecode(j['summary'] as String) as Json;
    }
    final now =
        (await tx.execute('SELECT CURRENT_TIMESTAMP')).single[0] as DateTime;
    if (s['active_job'] != jobId ||
        j['lease'] != body['lease'] ||
        j['status'] != 'running' ||
        !(j['lease_until'] as DateTime).isAfter(now)) {
      throw const ApiError(409, 'lease_lost');
    }
    if (body['action'] == 'heartbeat') {
      await tx.execute(
        Sql.named(
          "UPDATE jobs SET lease_until=CURRENT_TIMESTAMP+interval '120 seconds' WHERE id=@j",
        ),
        parameters: {'j': jobId},
      );
      return {'ok': true};
    }
    if (body['action'] == 'fail') {
      final error = body['error'] as String;
      if (!RegExp(r'^[a-z0-9_]{1,80}$').hasMatch(error)) {
        throw const ApiError(400, 'schema');
      }
      await _finish(tx, s, jobId, 'failed', error: error);
      return {'ok': true};
    }
    if (body['action'] != 'complete') throw const ApiError(400, 'schema');
    final input = body['result'] as Json;
    final fetched = DateTime.parse(input['fetchedAt'] as String);
    if (fetched.isAfter(now.add(const Duration(minutes: 5))) ||
        fetched.isBefore(j['created_at'] as DateTime)) {
      throw const ApiError(400, 'invalid_timestamp');
    }
    final old =
        (await tx.execute('SELECT payload FROM catalog WHERE id=1 FOR UPDATE'))
                .single[0]
            as String;
    final merged = mergeImport(
      jsonDecode(old) as Json,
      jsonDecode(s['config'] as String) as Json,
      input,
      jobId,
    );
    merged['publishedAt'] = now.toUtc().toIso8601String();
    final partial = (input['catalogueStatus'] as List).any(
      (s) => s['status'] == 'failed',
    );
    final summary = <String, dynamic>{
      'schemaVersion': 1,
      'jobId': jobId,
      'published': true,
      'partial': partial,
      'branchCount': (input['branches'] as List).length,
      'itemCount': (input['items'] as List).length,
    };
    await tx.execute(
      Sql.named('UPDATE catalog SET payload=@j WHERE id=1'),
      parameters: {'j': jsonEncode(merged)},
    );
    final oldItems = await tx.execute(
      Sql.named('SELECT payload FROM source_items WHERE source_id=@s'),
      parameters: {'s': source},
    );
    final items = <String, Json>{
      if (oldItems.isNotEmpty)
        for (final i
            in (jsonDecode(oldItems.single[0] as String) as List).cast<Json>())
          i['id'] as String: i,
      for (final i in (input['items'] as List).cast<Json>())
        i['id'] as String: i,
    };
    await tx.execute(
      Sql.named(
        '''INSERT INTO source_items VALUES(@s,@j,CURRENT_TIMESTAMP) ON CONFLICT(source_id) DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at''',
      ),
      parameters: {'s': source, 'j': jsonEncode(items.values.toList())},
    );
    await tx.execute(
      Sql.named(
        'INSERT INTO directory_outbox(event_id,payload) VALUES(@id,@j)',
      ),
      parameters: {
        'id': jobId,
        'j': jsonEncode({
          'schemaVersion': 1,
          'type': 'DirectoryPublished',
          'sourceId': source,
          'version': jobId,
        }),
      },
    );
    await _finish(
      tx,
      s,
      jobId,
      'succeeded',
      error: partial ? 'partial_catalogue' : null,
      receipt: digest,
      summary: summary,
    );
    return summary;
  });

  Future<Response> call(Request req) async {
    final origin = req.headers['origin'];
    final cors = <String, String>{
      if (origin != null && allowedOrigins.contains(origin))
        'access-control-allow-origin': origin,
      'vary': 'origin',
    };
    Response json(int code, Object? payload) => Response(
      code,
      body: jsonEncode(payload),
      headers: {
        ...cors,
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
      },
    );
    try {
      final p = req.url.pathSegments;
      if (req.method == 'GET' && req.url.path == 'health') {
        await db.execute('SELECT 1 FROM directory_schema WHERE version=1');
        return json(200, {'status': 'ok'});
      }
      if (req.method == 'GET' && req.url.path == 'v1/directory/catalog') {
        final payload =
            (await db.execute('SELECT payload FROM catalog WHERE id=1'))
                    .single[0]
                as String;
        return json(200, jsonDecode(payload));
      }
      if (req.method == 'GET' && req.url.path == 'v1/directory/sources') {
        final rows = await db.execute(
          'SELECT id,config,enabled,interval_seconds,next_run,last_success,last_error,active_job FROM sources ORDER BY id',
        );
        return json(200, {
          'schemaVersion': 1,
          'sources': [
            for (final row in rows)
              {
                'id': row[0],
                'configuration': jsonDecode(row[1] as String),
                'enabled': row[2],
                'intervalSeconds': row[3],
                'nextRunAt': (row[4] as DateTime).toUtc().toIso8601String(),
                'lastSuccessAt': (row[5] as DateTime?)
                    ?.toUtc()
                    .toIso8601String(),
                'lastError': row[6],
                'running': row[7] != null,
              },
          ],
        });
      }
      if (p.length >= 3 && p[0] == 'internal' && p[1] == 'sources') {
        final source = p[2];
        if (!sourceKeys.containsKey(source)) {
          throw const ApiError(404, 'not_found');
        }
        if (p.length == 4 && p[3] == 'settings' && req.method == 'PATCH') {
          _authorize(req, adminKey);
          final b = await _body(req);
          if (b['enabled'] is! bool ||
              b['intervalSeconds'] is! int ||
              (b['intervalSeconds'] as int) < 3600 ||
              (b['intervalSeconds'] as int) > 604800) {
            throw const ApiError(400, 'schema');
          }
          await db.execute(
            Sql.named(
              'UPDATE sources SET enabled=@e,interval_seconds=@i WHERE id=@s',
            ),
            parameters: {
              'e': b['enabled'],
              'i': b['intervalSeconds'],
              's': source,
            },
          );
          return json(200, {'ok': true});
        }
        if (p.length == 4 && p[3] == 'refresh' && req.method == 'POST') {
          _authorize(req, adminKey);
          await db.execute(
            Sql.named(
              'UPDATE sources SET next_run=CURRENT_TIMESTAMP WHERE id=@s',
            ),
            parameters: {'s': source},
          );
          return json(200, {'ok': true});
        }
        if (p.length == 4 && p[3] == 'runs' && req.method == 'GET') {
          _authorize(req, adminKey);
          final rows = await db.execute(
            Sql.named(
              'SELECT id,status,attempt,created_at,finished_at,error,summary FROM jobs WHERE source_id=@s ORDER BY created_at DESC LIMIT 30',
            ),
            parameters: {'s': source},
          );
          return json(200, {
            'runs': [
              for (final r in rows)
                {
                  'jobId': r[0],
                  'status': r[1],
                  'attempt': r[2],
                  'createdAt': (r[3] as DateTime).toUtc().toIso8601String(),
                  'finishedAt': (r[4] as DateTime?)?.toUtc().toIso8601String(),
                  'error': r[5],
                  'summary': r[6] == null ? null : jsonDecode(r[6] as String),
                },
            ],
          });
        }
        if (p.length == 4 && p[3] == 'items' && req.method == 'GET') {
          _authorize(req, adminKey);
          final rows = await db.execute(
            Sql.named('SELECT payload FROM source_items WHERE source_id=@s'),
            parameters: {'s': source},
          );
          return json(200, {
            'items': rows.isEmpty ? [] : jsonDecode(rows.single[0] as String),
          });
        }
        _authorize(req, sourceKeys[source]!);
        if (p.length == 4 && p[3] == 'claim' && req.method == 'POST') {
          return json(200, {'job': await claim(source)});
        }
        if (p.length == 5 && p[3] == 'jobs' && req.method == 'POST') {
          return json(200, await result(source, p[4], await _body(req)));
        }
      }
      throw const ApiError(404, 'not_found');
    } on ApiError catch (e) {
      return json(e.status, {'error': e.code});
    } on FormatException catch (e) {
      return json(400, {
        'error': RegExp(r'^[a-z_]+$').hasMatch(e.message)
            ? e.message
            : 'schema',
      });
    } on TypeError {
      return json(400, {'error': 'schema'});
    } on ArgumentError {
      return json(400, {'error': 'schema'});
    } catch (_) {
      return json(503, {'error': 'unavailable'});
    }
  }
}
