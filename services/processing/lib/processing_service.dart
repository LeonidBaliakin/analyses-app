import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:cloud_access/cloud_access.dart';
import 'package:shelf/shelf.dart';

final class ProcessingApiError implements Exception {
  const ProcessingApiError(this.status, this.code);
  final int status;
  final String code;
}

Future<Uint8List> bounded(Stream<List<int>> stream, int max) async {
  final b = BytesBuilder();
  await for (final chunk in stream.timeout(const Duration(seconds: 30))) {
    if (b.length + chunk.length > max) {
      throw const ProcessingApiError(413, 'too_large');
    }
    b.add(chunk);
  }
  return b.takeBytes();
}

abstract interface class JobWorker {
  Future<String?> runtimeId();
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> metadata,
    Uint8List bytes,
    String runtimeId,
    Future<void> Function(String, Map<String, dynamic>?) progress,
    Future<bool> Function() cancelled,
  );
}

final class PythonJobWorker implements JobWorker {
  PythonJobWorker({
    required this.python,
    required this.script,
    required this.config,
  });
  final String python, script, config;
  @override
  Future<String?> runtimeId() async {
    try {
      final p = await Process.run(python, [
        script,
        '--config',
        config,
        '--capabilities',
      ]).timeout(const Duration(seconds: 15));
      final j = jsonDecode((p.stdout as String).trim()) as Map;
      return j['ready'] == true ? j['runtimeId'] as String : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> metadata,
    Uint8List bytes,
    String runtime,
    Future<void> Function(String, Map<String, dynamic>?) progress,
    Future<bool> Function() cancelled,
  ) async {
    final dir = await Directory.systemTemp.createTemp('processing-job-');
    Process? process;
    Timer? timer;
    var timedOut = false;
    try {
      final file = File('${dir.path}/input');
      await file.writeAsBytes(bytes, flush: true);
      process = await Process.start(python, [
        script,
        '--config',
        config,
        '--file',
        file.path,
      ]);
      process.stdin.writeln(jsonEncode({...metadata, 'runtimeId': runtime}));
      await process.stdin.close();
      final stderrDrain = process.stderr.drain<void>();
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          if (await cancelled()) process?.kill();
        } catch (_) {
          process?.kill();
        }
      });
      final timeout = Timer(const Duration(seconds: 210), () {
        timedOut = true;
        process?.kill();
      });
      Map<String, dynamic>? result;
      var outputBytes = 0;
      try {
        await for (final line
            in process.stdout
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          outputBytes += line.length;
          if (outputBytes > 4 * 1024 * 1024) {
            throw const ProcessingApiError(422, 'worker_output_limit');
          }
          final j = jsonDecode(line) as Map<String, dynamic>;
          if (j['stage'] == 'failed') {
            throw ProcessingApiError(422, j['error'] as String);
          }
          if (j['stage'] == 'ready') {
            result = Map<String, dynamic>.from(j['draft'] as Map);
          } else if (['ocr', 'extracting'].contains(j['stage'])) {
            await progress(
              j['stage'] as String,
              j.containsKey('pages') ? j : null,
            );
          }
        }
        await process.exitCode;
        await stderrDrain;
      } finally {
        timeout.cancel();
      }
      if (await cancelled()) throw const ProcessingApiError(409, 'cancelled');
      if (result == null) {
        throw ProcessingApiError(
          422,
          timedOut ? 'processing_timeout' : 'worker_failed',
        );
      }
      return result;
    } finally {
      timer?.cancel();
      process?.kill();
      if (process != null) {
        try {
          await process.exitCode.timeout(const Duration(seconds: 3));
        } catch (_) {
          process.kill(ProcessSignal.sigkill);
        }
      }
      await dir.delete(recursive: true);
    }
  }
}

final class ProcessingService {
  ProcessingService({
    required this.db,
    required this.documents,
    required this.worker,
    this.allowedOrigins = const {},
    this.cloudPolicies,
    http.Client? client,
  }) : client = client ?? http.Client();
  final Pool db;
  final Uri documents;
  final JobWorker worker;
  final Set<String> allowedOrigins;
  final http.Client client;
  final CloudPolicyGateway? cloudPolicies;
  Future<CloudPolicy?> _policy(String owner) async {
    if (cloudPolicies == null) return null;
    try {
      return await cloudPolicies!.policy(owner);
    } catch (_) {
      throw const ProcessingApiError(503, 'cloud_access_unavailable');
    }
  }

  Future<Map<String, Object?>> usage(String owner) async {
    final result = await db.execute(
      Sql.named(
        "SELECT to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM'),count(*) FILTER(WHERE state='used'),count(*) FILTER(WHERE state='reserved') FROM processing_quota WHERE owner_id=@o AND period=to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM')",
      ),
      parameters: {'o': owner},
    );
    return {
      'period': result.single[0],
      'usedJobs': result.single[1],
      'reservedJobs': result.single[2],
    };
  }

  bool working = false;
  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786205)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS processing_schema(id integer PRIMARY KEY CHECK(id=1),version integer NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO processing_schema VALUES(1,1) ON CONFLICT DO NOTHING',
    );
    final version =
        (await tx.execute('SELECT version FROM processing_schema')).single[0]
            as int;
    if (version != 1 && version != 2) {
      throw StateError('Unsupported processing schema');
    }
    await tx.execute(
      '''CREATE TABLE IF NOT EXISTS jobs(owner_id text,profile_id text,job_id text,original_id text,
      request text NOT NULL,metadata text NOT NULL,input_bytes bytea NOT NULL,status text NOT NULL,
      runtime_id text NOT NULL,artifact text,draft text,error_code text,updated_at timestamptz NOT NULL,PRIMARY KEY(owner_id,job_id))''',
    );
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS processing_outbox(event_id text PRIMARY KEY,payload text NOT NULL,created_at timestamptz NOT NULL)',
    );
    await tx.execute(
      "CREATE TABLE IF NOT EXISTS processing_quota(owner_id text,job_id text,period text NOT NULL,state text NOT NULL CHECK(state IN ('reserved','used','released')),PRIMARY KEY(owner_id,job_id))",
    );
    if (version == 1) {
      await tx.execute(
        "INSERT INTO processing_quota SELECT owner_id,job_id,CASE WHEN status IN ('queued','ocr','extracting') THEN to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM') ELSE 'legacy' END,CASE WHEN status='ready' THEN 'used' WHEN status IN ('queued','ocr','extracting') THEN 'reserved' ELSE 'released' END FROM jobs ON CONFLICT DO NOTHING",
      );
      await tx.execute('UPDATE processing_schema SET version=2');
    }
    await tx.execute(
      "UPDATE jobs SET status='queued' WHERE status IN ('ocr','extracting')",
    );
  });
  Future<(Map<String, dynamic>, Uint8List)> _documents(
    String path,
    String auth, {
    bool bytes = false,
  }) async {
    final req = http.Request('GET', documents.resolve(path))
      ..followRedirects = false;
    req.headers['authorization'] = auth;
    final response = await client
        .send(req)
        .timeout(const Duration(seconds: 30));
    final body = await bounded(
      response.stream,
      bytes ? 20 * 1024 * 1024 : 16384,
    );
    if (response.statusCode != 200) {
      throw ProcessingApiError(
        response.statusCode == 401
            ? 401
            : response.statusCode == 404
            ? 404
            : 503,
        'documents_access',
      );
    }
    return (
      bytes
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(body)) as Map<String, dynamic>,
      body,
    );
  }

  Response _json(int status, Map<String, Object?> j) => Response(
    status,
    body: jsonEncode(j),
    headers: {'content-type': 'application/json', 'cache-control': 'no-store'},
  );
  Map<String, Object?> _view(Map<String, dynamic> r) => {
    'schemaVersion': 1,
    'jobId': r['job_id'],
    'profileId': r['profile_id'],
    'originalId': r['original_id'],
    'runtimeId': r['runtime_id'],
    'status': r['status'],
    'error': r['error_code'],
    'artifact': r['artifact'] == null
        ? null
        : jsonDecode(r['artifact'] as String),
    'draft': r['draft'] == null ? null : jsonDecode(r['draft'] as String),
  };
  Future<Response> call(Request req) async {
    final origin = req.headers['origin'];
    if (origin != null && !allowedOrigins.contains(origin)) {
      return _json(403, {'error': 'origin_denied'});
    }
    Response response;
    try {
      if (req.method == 'OPTIONS') {
        response = Response(
          204,
          headers: {
            'access-control-allow-methods': 'GET,POST,OPTIONS',
            'access-control-allow-headers': 'Authorization,Content-Type',
          },
        );
      } else if (req.url.path == 'health') {
        response = _json(200, {'status': 'ok'});
      } else {
        final p = req.url.pathSegments,
            auth = req.headers['authorization'] ?? '';
        if (p.length < 4 ||
            p[0] != 'v1' ||
            p[1] != 'profiles' ||
            !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(p[2])) {
          throw const ProcessingApiError(404, 'not_found');
        }
        final profile = p[2],
            access = (await _documents(
              'v1/profiles/$profile/processing-access',
              auth,
            )).$1,
            owner = access['ownerId'] as String;
        if (p.length == 4 &&
            p[3] == 'processing-capabilities' &&
            req.method == 'GET') {
          final runtime = await worker.runtimeId();
          CloudPolicy? policy;
          try {
            policy = await _policy(owner);
          } on ProcessingApiError {
            /* Existing jobs remain readable. */
          }
          final quota = await usage(owner);
          response = _json(200, {
            'schemaVersion': 1,
            'runtimeId': runtime,
            'ownerId': owner,
            'profileId': profile,
            'ready':
                runtime != null &&
                access['processingAllowed'] == true &&
                (policy?.canProcess ?? cloudPolicies == null) &&
                (policy == null ||
                    (quota['usedJobs'] as int) +
                            (quota['reservedJobs'] as int) <
                        policy.processingMonthlyLimit),
            'processingAllowed':
                access['processingAllowed'] == true &&
                (policy?.canProcess ?? cloudPolicies == null),
            'quota': {...quota, 'limitJobs': policy?.processingMonthlyLimit},
          });
        } else if (p.length == 4 &&
            p[3] == 'processing-jobs' &&
            req.method == 'POST') {
          if (access['processingAllowed'] != true) {
            throw const ProcessingApiError(403, 'processing_denied');
          }
          final policy = await _policy(owner);
          if (policy != null && !policy.canProcess) {
            throw const ProcessingApiError(403, 'processing_denied');
          }
          final b = jsonDecode(
            utf8.decode(await bounded(req.read(), 8192)),
          ) as Map<String, dynamic>;
          final id = b['jobId'] as String,
              original = b['originalId'] as String,
              runtime = b['runtimeId'] as String;
          if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id) ||
              !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(original)) {
            throw const ProcessingApiError(400, 'invalid_id');
          }
          final fingerprint = jsonEncode({
            'originalId': original,
            'runtimeId': runtime,
            'terminologyReleaseId': b['terminologyReleaseId'] as String,
          });
          final old = await db.execute(
            Sql.named('SELECT * FROM jobs WHERE owner_id=@o AND job_id=@i'),
            parameters: {'o': owner, 'i': id},
          );
          if (old.isNotEmpty) {
            final row = old.single.toColumnMap();
            if (row['profile_id'] != profile || row['request'] != fingerprint) {
              throw const ProcessingApiError(409, 'operation_mismatch');
            }
            response = _json(200, _view(row));
          } else {
            if (await worker.runtimeId() != runtime) {
              throw const ProcessingApiError(409, 'runtime_changed');
            }
            final meta = (await _documents(
              'v1/profiles/$profile/originals/$original',
              auth,
            )).$1;
            if (meta['ownerId'] != owner ||
                meta['profileId'] != profile ||
                meta['originalId'] != original ||
                meta['state'] != 'ready') {
              throw const ProcessingApiError(404, 'not_found');
            }
            final bytes = (await _documents(
              'v1/profiles/$profile/originals/$original/content',
              auth,
              bytes: true,
            )).$2;
            if (bytes.length != meta['size'] ||
                sha256.convert(bytes).toString() != meta['sha256']) {
              throw const ProcessingApiError(422, 'integrity');
            }
            await db.runTx((tx) async {
              await tx.execute(
                Sql.named('SELECT pg_advisory_xact_lock(hashtext(@o))'),
                parameters: {'o': owner},
              );
              final pending =
                  (await tx.execute(
                        Sql.named(
                          "SELECT count(*) FROM jobs WHERE owner_id=@o AND status IN ('queued','ocr','extracting')",
                        ),
                        parameters: {'o': owner},
                      )).single[0]
                      as int;
              final exists = await tx.execute(
                Sql.named('SELECT 1 FROM jobs WHERE owner_id=@o AND job_id=@i'),
                parameters: {'o': owner, 'i': id},
              );
              if (exists.isEmpty && pending >= 3) {
                throw const ProcessingApiError(429, 'queue_full');
              }
              final period =
                  (await tx.execute(
                        "SELECT to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM')",
                      )).single[0]
                      as String;
              if (exists.isEmpty && policy != null) {
                // Refresh rights under the admission lock, then reserve a monthly
                // slot in the same transaction that creates the job.
                final current = await _policy(owner);
                if (!current!.canProcess) {
                  throw const ProcessingApiError(403, 'processing_denied');
                }
                final count =
                    (await tx.execute(
                          Sql.named(
                            "SELECT count(*) FROM processing_quota WHERE owner_id=@o AND period=@p AND state IN ('used','reserved')",
                          ),
                          parameters: {'o': owner, 'p': period},
                        )).single[0]
                        as int;
                if (count >= current.processingMonthlyLimit) {
                  throw const ProcessingApiError(
                    409,
                    'processing_quota_exceeded',
                  );
                }
              }
              await tx.execute(
                Sql.named(
                  "INSERT INTO jobs(owner_id,profile_id,job_id,original_id,request,metadata,input_bytes,status,runtime_id,updated_at) VALUES(@o,@p,@i,@r,@q,@m,@b,'queued',@v,CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING",
                ),
                parameters: {
                  'o': owner,
                  'p': profile,
                  'i': id,
                  'r': original,
                  'q': fingerprint,
                  'm': jsonEncode(meta),
                  'b': TypedValue(Type.byteArray, bytes),
                  'v': runtime,
                },
              );
              if (exists.isEmpty) {
                await tx.execute(
                  Sql.named(
                    "INSERT INTO processing_quota VALUES(@o,@i,@p,'reserved')",
                  ),
                  parameters: {'o': owner, 'i': id, 'p': period},
                );
              }
            });
            final row = (await db.execute(
              Sql.named('SELECT * FROM jobs WHERE owner_id=@o AND job_id=@i'),
              parameters: {'o': owner, 'i': id},
            )).single.toColumnMap();
            if (row['profile_id'] != profile || row['request'] != fingerprint) {
              throw const ProcessingApiError(409, 'operation_mismatch');
            }
            response = _json(200, _view(row));
          }
        } else if (p.length >= 5 && p[3] == 'processing-jobs') {
          final id = p[4],
              rows = await db.execute(
                Sql.named(
                  'SELECT * FROM jobs WHERE owner_id=@o AND profile_id=@p AND job_id=@i',
                ),
                parameters: {'o': owner, 'p': profile, 'i': id},
              );
          if (rows.isEmpty) throw const ProcessingApiError(404, 'not_found');
          if (p.length == 6 && p[5] == 'cancel' && req.method == 'POST') {
            await db.runTx((tx) async {
              final changed = await tx.execute(
                Sql.named(
                  "UPDATE jobs SET status='cancelled',input_bytes=''::bytea,updated_at=CURRENT_TIMESTAMP WHERE owner_id=@o AND job_id=@i AND status NOT IN ('ready','failed','cancelled')",
                ),
                parameters: {'o': owner, 'i': id},
              );
              if (changed.affectedRows > 0) {
                await tx.execute(
                  Sql.named(
                    "UPDATE processing_quota SET state='released' WHERE owner_id=@o AND job_id=@i AND state='reserved'",
                  ),
                  parameters: {'o': owner, 'i': id},
                );
              }
            });
            response = _json(200, {'state': 'cancelled'});
          } else if (p.length == 5 && req.method == 'GET') {
            response = _json(200, _view(rows.single.toColumnMap()));
          } else {
            throw const ProcessingApiError(404, 'not_found');
          }
        } else {
          throw const ProcessingApiError(404, 'not_found');
        }
      }
    } on ProcessingApiError catch (e) {
      response = _json(e.status, {'error': e.code});
    } on FormatException {
      response = _json(400, {'error': 'schema'});
    } on TypeError {
      response = _json(400, {'error': 'schema'});
    } catch (_) {
      response = _json(503, {'error': 'unavailable'});
    }
    return response.change(
      headers: {
        'access-control-allow-origin': ?origin,
        if (origin != null) 'vary': 'Origin',
        'x-content-type-options': 'nosniff',
      },
    );
  }

  Future<void> tick() async {
    if (working) return;
    working = true;
    try {
      final row = await db.runTx((tx) async {
        final rows = await tx.execute(
          "SELECT * FROM jobs WHERE status='queued' ORDER BY updated_at FOR UPDATE SKIP LOCKED LIMIT 1",
        );
        if (rows.isEmpty) return null;
        final row = rows.single.toColumnMap();
        final policy = await _policy(row['owner_id'] as String);
        if (policy != null && !policy.canProcess) {
          await tx.execute(
            Sql.named(
              "UPDATE jobs SET status='cancelled',error_code='processing_denied',input_bytes=''::bytea WHERE owner_id=@o AND job_id=@i",
            ),
            parameters: {'o': row['owner_id'], 'i': row['job_id']},
          );
          await tx.execute(
            Sql.named(
              "UPDATE processing_quota SET state='released' WHERE owner_id=@o AND job_id=@i AND state='reserved'",
            ),
            parameters: {'o': row['owner_id'], 'i': row['job_id']},
          );
          return null;
        }
        await tx.execute(
          Sql.named(
            "UPDATE jobs SET status='ocr',updated_at=CURRENT_TIMESTAMP WHERE owner_id=@o AND job_id=@i",
          ),
          parameters: {'o': row['owner_id'], 'i': row['job_id']},
        );
        return row;
      });
      if (row == null) return;
      final args = {'o': row['owner_id'], 'i': row['job_id']};
      Future<bool> cancelled() async {
        final policy = await _policy(row['owner_id'] as String);
        if (policy != null && !policy.canProcess) return true;
        return (await db.execute(
              Sql.named(
                'SELECT status FROM jobs WHERE owner_id=@o AND job_id=@i',
              ),
              parameters: args,
            )).single[0] ==
            'cancelled';
      }

      try {
        final draft = await worker.run(
          jsonDecode(row['metadata'] as String) as Map<String, dynamic>,
          row['input_bytes'] as Uint8List,
          row['runtime_id'] as String,
          (stage, artifact) async {
            await db.execute(
              Sql.named(
                "UPDATE jobs SET status=@s,artifact=COALESCE(@a,artifact),updated_at=CURRENT_TIMESTAMP WHERE owner_id=@o AND job_id=@i AND status NOT IN ('cancelled','ready')",
              ),
              parameters: {
                ...args,
                's': stage,
                'a': artifact == null ? null : jsonEncode(artifact),
              },
            );
          },
          cancelled,
        );
        if (await cancelled()) {
          throw const ProcessingApiError(403, 'processing_denied');
        }
        await db.runTx((tx) async {
          final changed = await tx.execute(
            Sql.named(
              "UPDATE jobs SET status='ready',draft=@d,input_bytes=''::bytea,updated_at=CURRENT_TIMESTAMP WHERE owner_id=@o AND job_id=@i AND status!='cancelled'",
            ),
            parameters: {...args, 'd': jsonEncode(draft)},
          );
          if (changed.affectedRows == 1) {
            await tx.execute(
              Sql.named(
                "UPDATE processing_quota SET state='used' WHERE owner_id=@o AND job_id=@i AND state='reserved'",
              ),
              parameters: args,
            );
            await tx.execute(
              Sql.named(
                'INSERT INTO processing_outbox VALUES(@id,@p,CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING',
              ),
              parameters: {
                'id': '${row['owner_id']}:${row['job_id']}',
                'p': jsonEncode({
                  'schemaVersion': 1,
                  'type': 'DraftReady',
                  'jobId': row['job_id'],
                  'originalId': row['original_id'],
                  'profileId': row['profile_id'],
                }),
              },
            );
          }
        });
      } catch (e) {
        await db.runTx((tx) async {
          final changed = await tx.execute(
            Sql.named(
              "UPDATE jobs SET status='failed',input_bytes=''::bytea,error_code=@e,updated_at=CURRENT_TIMESTAMP WHERE owner_id=@o AND job_id=@i AND status!='cancelled'",
            ),
            parameters: {
              ...args,
              'e': e is ProcessingApiError ? e.code : 'worker_failed',
            },
          );
          if (changed.affectedRows > 0) {
            await tx.execute(
              Sql.named(
                "UPDATE processing_quota SET state='released' WHERE owner_id=@o AND job_id=@i AND state='reserved'",
              ),
              parameters: args,
            );
          }
        });
      }
    } finally {
      working = false;
    }
  }
}
