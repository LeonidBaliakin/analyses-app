import 'dart:async';
import 'dart:convert';

import 'package:cloud_access/cloud_access.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgres/postgres.dart';
import 'package:processing_service/processing_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class TestWorker implements JobWorker {
  bool unavailable = false;
  String? failure;
  Completer<void>? barrier;
  int calls = 0;
  @override
  Future<String?> runtimeId() async => unavailable ? null : 'r1';
  @override
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> metadata,
    Uint8List bytes,
    String runtime,
    Future<void> Function(String, Map<String, dynamic>?) progress,
    Future<bool> Function() cancelled,
  ) async {
    calls++;
    await progress('extracting', {
      'runtimeId': runtime,
      'versions': {'ocr': 'o1', 'model': 'm1', 'prompt': 'p1', 'worker': 'w1'},
      'pages': [
        {'number': 1, 'text': 'Synthetic OCR'},
      ],
    });
    if (barrier != null) await barrier!.future;
    if (failure != null) throw ProcessingApiError(422, failure!);
    return {'schemaVersion': 1, 'runtimeId': runtime, 'rows': []};
  }
}

class TestPolicies implements CloudPolicyGateway {
  bool sync = true, storage = true, processing = true, unavailable = false;
  int records = 2, bytes = 1000, jobs = 1;
  @override
  Future<CloudPolicy> policy(String owner) async {
    if (unavailable) throw const CloudAccessFailure();
    return CloudPolicy(
      ownerId: owner,
      revision: 1,
      syncEnabled: sync,
      storageEnabled: storage,
      processingEnabled: processing,
      recordLimit: records,
      storageLimitBytes: bytes,
      processingMonthlyLimit: jobs,
    );
  }
}

void main() {
  final file = File('../../infra/documents/.env');
  if (!file.existsSync()) {
    test('PostgreSQL integration', () {}, skip: 'Initialize local stack');
    return;
  }
  final env = {
    for (final l in file.readAsLinesSync())
      l.split('=').first: l.substring(l.indexOf('=') + 1),
  };
  final db = Pool.withUrl(
    'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/processing_tests?sslmode=disable',
  );
  final bytes = Uint8List.fromList(utf8.encode('%PDF-1.7 synthetic'));
  late ProcessingService api;
  late TestWorker worker;
  bool corrupt = false, denied = false;
  Future<Response> call(
    String method,
    String path, {
    String token = 'a',
    String profile = 'p',
    Map<String, Object?>? body,
  }) => api.call(
    Request(
      method,
      Uri.parse('http://localhost/v1/profiles/$profile/$path'),
      headers: {'authorization': 'Bearer $token'},
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Map<String, Object?> request(String id, {String original = 'o'}) => {
    'jobId': id,
    'originalId': original,
    'runtimeId': 'r1',
    'terminologyReleaseId': 'terms1',
  };
  Future<int> count(String table) async =>
      (await db.execute('SELECT count(*) FROM $table')).single[0] as int;
  setUpAll(() async {
    await ProcessingService(
      db: db,
      documents: Uri.parse('http://documents/'),
      worker: TestWorker(),
    ).migrate();
  });
  tearDownAll(() => db.close());
  setUp(() async {
    await db.execute('TRUNCATE jobs,processing_outbox,processing_quota');
    worker = TestWorker();
    corrupt = false;
    denied = false;
    api = ProcessingService(
      db: db,
      documents: Uri.parse('http://documents/'),
      worker: worker,
      client: MockClient((req) async {
        final token = req.headers['authorization'];
        final p = req.url.pathSegments;
        if (token != 'Bearer a' && token != 'Bearer b') {
          return http.Response('{}', 401);
        }
        if (p[2] != 'p') return http.Response('{}', 404);
        final owner = token == 'Bearer a' ? 'owner-a' : 'owner-b';
        if (p.last == 'processing-access') {
          return http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'ownerId': owner,
              'profileId': 'p',
              'processingAllowed': !denied,
            }),
            200,
          );
        }
        if (p.last == 'content') {
          return http.Response.bytes(corrupt ? [0] : bytes, 200);
        }
        return http.Response(
          jsonEncode({
            'schemaVersion': 1,
            'state': 'ready',
            'ownerId': owner,
            'profileId': 'p',
            'originalId': p.last,
            'documentId': 'd',
            'size': bytes.length,
            'sha256': sha256.convert(bytes).toString(),
            'mime': 'application/pdf',
          }),
          200,
        );
      }),
    );
  });
  test(
    'authorization/profile scope and replay create one job and one event',
    () async {
      expect(
        (await call(
          'GET',
          'processing-capabilities',
          token: 'invalid',
        )).statusCode,
        401,
      );
      expect(
        (await call(
          'POST',
          'processing-jobs',
          profile: 'foreign',
          body: request('j'),
        )).statusCode,
        404,
      );
      expect(
        (await call('POST', 'processing-jobs', body: request('j'))).statusCode,
        200,
      );
      expect(
        (await call('POST', 'processing-jobs', body: request('j'))).statusCode,
        200,
      );
      expect(await count('jobs'), 1);
      expect(
        (await call('GET', 'processing-jobs/j', token: 'b')).statusCode,
        404,
      );
      expect(
        (await call(
          'POST',
          'processing-jobs',
          body: request('j', original: 'different'),
        )).statusCode,
        409,
      );
      await api.tick();
      await api.tick();
      expect(worker.calls, 1);
      expect(await count('processing_outbox'), 1);
      final j = jsonDecode(
        await (await call('GET', 'processing-jobs/j')).readAsString(),
      ) as Map;
      expect(j['status'], 'ready');
      expect(j['artifact'], isNotNull);
      expect(
        (await db.execute('SELECT octet_length(input_bytes) FROM jobs'))
            .single[0],
        0,
      );
      await api.migrate();
      await api.tick();
      expect(worker.calls, 1);
      expect(await count('processing_outbox'), 1);
    },
  );
  test(
    'concurrent replay/limits and original integrity/entitlement checks',
    () async {
      final results = await Future.wait(
        List.generate(
          5,
          (_) => call('POST', 'processing-jobs', body: request('same')),
        ),
      );
      expect(results.map((r) => r.statusCode), everyElement(200));
      expect(await count('jobs'), 1);
      for (final id in ['two', 'three']) {
        expect(
          (await call('POST', 'processing-jobs', body: request(id))).statusCode,
          200,
        );
      }
      expect(
        (await call(
          'POST',
          'processing-jobs',
          body: request('four'),
        )).statusCode,
        429,
      );
      denied = true;
      expect(
        (await call(
          'POST',
          'processing-jobs',
          body: request('same'),
        )).statusCode,
        403,
      );
      denied = false;
      await db.execute('TRUNCATE jobs');
      corrupt = true;
      expect(
        (await call(
          'POST',
          'processing-jobs',
          body: request('corrupt'),
        )).statusCode,
        422,
      );
      expect(await count('jobs'), 0);
    },
  );
  test(
    'cancel prevents ready; failure keeps OCR; restart retries interrupted job',
    () async {
      await call('POST', 'processing-jobs', body: request('j'));
      worker.barrier = Completer<void>();
      final run = api.tick();
      while ((await db.execute('SELECT status FROM jobs')).single[0] !=
          'extracting') {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        (await call('POST', 'processing-jobs/j/cancel', token: 'b')).statusCode,
        404,
      );
      expect((await call('POST', 'processing-jobs/j/cancel')).statusCode, 200);
      worker.barrier!.complete();
      await run;
      expect(
        (await db.execute('SELECT status FROM jobs')).single[0],
        'cancelled',
      );
      expect(await count('processing_outbox'), 0);
      worker.barrier = null;
      worker.failure = 'llm_timeout';
      await call('POST', 'processing-jobs', body: request('failed'));
      await api.tick();
      final failed = (await db.execute(
        "SELECT status,artifact FROM jobs WHERE job_id='failed'",
      )).single;
      expect(failed[0], 'failed');
      expect(failed[1], isNotNull);
      worker.failure = null;
      await call('POST', 'processing-jobs', body: request('restart'));
      await db.execute("UPDATE jobs SET status='ocr' WHERE job_id='restart'");
      await api.migrate();
      await api.tick();
      expect(
        (await db.execute("SELECT status FROM jobs WHERE job_id='restart'"))
            .single[0],
        'ready',
      );
    },
  );
  test('monthly slots: concurrent replay, cancellation/failure release, completion and rollover', () async {
    final policy = TestPolicies();
    api = ProcessingService(
      db: db,
      documents: api.documents,
      worker: worker,
      client: api.client,
      cloudPolicies: policy,
    );
    final pair = await Future.wait([
      call('POST', 'processing-jobs', body: request('j')),
      call('POST', 'processing-jobs', body: request('j')),
    ]);
    expect(pair.every((r) => r.statusCode == 200), true);
    expect(await count('processing_quota'), 1);
    expect(
      (await call('POST', 'processing-jobs', body: request('over'))).statusCode,
      409,
    );
    await call('POST', 'processing-jobs/j/cancel');
    expect((await api.usage('owner-a'))['reservedJobs'], 0);
    worker.failure = 'synthetic_failure';
    expect(
      (await call('POST', 'processing-jobs', body: request('fail'))).statusCode,
      200,
    );
    await api.tick();
    expect((await api.usage('owner-a'))['reservedJobs'], 0);
    worker.failure = null;
    await call('POST', 'processing-jobs', body: request('success'));
    await api.tick();
    expect((await api.usage('owner-a'))['usedJobs'], 1);
    expect(
      (await call(
        'POST',
        'processing-jobs',
        body: request('success'),
      )).statusCode,
      200,
    );
    expect((await api.usage('owner-a'))['usedJobs'], 1);
    await db.execute("UPDATE processing_quota SET period='2000-01'");
    expect(
      (await call(
        'POST',
        'processing-jobs',
        body: request('new-month'),
      )).statusCode,
      200,
    );
    policy.processing = false;
    await api.tick();
    expect((await api.usage('owner-a'))['reservedJobs'], 0);
    expect((await call('GET', 'processing-jobs/success')).statusCode, 200);
    expect(
      (await call(
        'POST',
        'processing-jobs',
        body: request('denied'),
      )).statusCode,
      403,
    );
    policy.unavailable = true;
    expect((await call('GET', 'processing-jobs/success')).statusCode, 200);
  });
  test('migration preserves jobs and reserves queued jobs only once', () async {
    await call('POST', 'processing-jobs', body: request('legacy'));
    await db.execute('DELETE FROM processing_quota');
    await db.execute('UPDATE processing_schema SET version=1');
    await api.migrate();
    await api.migrate();
    expect(await count('jobs'), 1);
    expect(await count('processing_quota'), 1);
    await api.tick();
    expect((await api.usage('owner-a'))['usedJobs'], 1);
  });

  test('quota ledger insert and completion outbox failures cannot leave a charged or orphan job', () async {
    final policy = TestPolicies();
    api = ProcessingService(
      db: db,
      documents: api.documents,
      worker: worker,
      client: api.client,
      cloudPolicies: policy,
    );
    await db.execute(
      "CREATE OR REPLACE FUNCTION fail_quota() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RAISE EXCEPTION ''synthetic quota failure''; END'",
    );
    await db.execute(
      'CREATE TRIGGER fail_quota BEFORE INSERT ON processing_quota FOR EACH ROW EXECUTE FUNCTION fail_quota()',
    );
    try {
      expect(
        (await call(
          'POST',
          'processing-jobs',
          body: request('atomic'),
        )).statusCode,
        503,
      );
      expect(await count('jobs'), 0);
      expect(await count('processing_quota'), 0);
    } finally {
      await db.execute('DROP TRIGGER fail_quota ON processing_quota');
    }
    await call('POST', 'processing-jobs', body: request('atomic'));
    await db.execute(
      'CREATE TRIGGER fail_quota BEFORE INSERT ON processing_outbox FOR EACH ROW EXECUTE FUNCTION fail_quota()',
    );
    try {
      await api.tick();
      final usage = await api.usage('owner-a');
      expect(usage['usedJobs'], 0);
      expect(usage['reservedJobs'], 0);
      expect(await count('processing_outbox'), 0);
    } finally {
      await db.execute('DROP TRIGGER fail_quota ON processing_outbox');
      await db.execute('DROP FUNCTION fail_quota()');
    }
  });
}
