import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:provider_directory_service/provider_directory_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Json branch(String id, {String network = 'synthetic', String? website}) => {
  'id': id,
  'network': network,
  'city': 'spb',
  'name': 'Synthetic branch',
  'address': 'Synthetic street, 1',
  'phone': '',
  'website': website ?? 'https://example.org/$id',
  'source': 'https://example.org/list',
  'checkedAt': '2026-11-27',
};
Json config(String id) => {
  'id': id,
  'name': id,
  'enabled': true,
  'intervalSeconds': 86400,
  'parserVersion': '1',
  'cities': ['spb'],
  'allowedOrigins': ['https://example.org'],
};
Json seed() => {
  'schemaVersion': 1,
  'version': 'seed',
  'checkedAt': '2026-11-27',
  'branches': [branch('synthetic-old', website: 'https://example.org/one')],
  'doctors': [
    {
      'id': 'doctor-1',
      'name': 'Synthetic doctor',
      'specialty': 'Synthetic specialty',
      'branchIds': ['synthetic-old'],
      'source': 'https://example.org/doctor',
    },
  ],
  'tests': <Json>[],
};
Json result() => {
  'schemaVersion': 1,
  'sourceId': 'synthetic',
  'parserVersion': '1',
  'fetchedAt': DateTime.now().toUtc().toIso8601String(),
  'branches': [branch('synthetic-new', website: 'https://example.org/one')],
  'items': [
    {
      'id': 'synthetic-item',
      'network': 'synthetic',
      'city': 'spb',
      'kind': 'test',
      'name': 'Source name',
      'source': 'https://example.org/test',
      'checkedAt': '2026-11-27',
    },
  ],
  'catalogueStatus': [
    {
      'url': 'https://example.org/catalogue',
      'city': 'spb',
      'status': 'observed',
      'pages': 1,
      'items': 1,
    },
  ],
};

void main() {
  test('coverage correction preserves excluded facts and is idempotent', () {
    final previous = seed();
    (previous['branches'] as List).add(
      branch('invitro-outside', network: 'invitro')
        ..['address'] = 'г. Кировск, Синтетическая, 2',
    );
    final corrected = constrainInvitroCoverage(previous);
    expect(corrected['branches'], hasLength(1));
    expect(
      (corrected['coverageReviewBranches'] as List).single['id'],
      'invitro-outside',
    );
    expect(constrainInvitroCoverage(corrected), same(corrected));
  });
  test('changed address clears coordinates from the old location', () {
    final previous = seed();
    (previous['branches'] as List).single.addAll({
      'lat': 59.9,
      'lon': 30.3,
      'coordinateSource': 'https://example.org/one',
    });
    final input = result();
    (input['branches'] as List).single['address'] = 'Synthetic new address, 2';
    final merged = mergeImport(previous, config('synthetic'), input, 'job');
    expect((merged['branches'] as List).single.containsKey('lat'), isFalse);
    expect((merged['branches'] as List).single['id'], 'synthetic-old');
  });
  test(
    'merge keeps verified identities, relationships and unknown coordinates',
    () {
      final merged = mergeImport(seed(), config('synthetic'), result(), 'job');
      expect((merged['branches'] as List).single['id'], 'synthetic-old');
      expect((merged['doctors'] as List).single['branchIds'], [
        'synthetic-old',
      ]);
      expect((merged['branches'] as List).single.containsKey('lat'), isFalse);
      expect(
        merged['tests'],
        isEmpty,
      ); // a source listing does not approve terminology
    },
  );
  test('cross-source, wrong city, external URLs and suspicious shrinkage are rejected', () {
    for (final change in <void Function(Json)>[
      (j) => (j['branches'] as List).single['network'] = 'other',
      (j) => (j['branches'] as List).single['city'] = 'voronezh',
      (j) =>
          (j['branches'] as List).single['source'] = 'https://evil.example/a',
      (j) => (j['branches'] as List).clear(),
    ]) {
      final j = result();
      change(j);
      expect(
        () => mergeImport(seed(), config('synthetic'), j, 'job'),
        throwsFormatException,
      );
    }
    final prior = seed();
    (prior['branches'] as List).add(branch('synthetic-second'));
    expect(
      () => mergeImport(prior, config('synthetic'), result(), 'job'),
      throwsFormatException,
    );
  });

  final url = Platform.environment['DIRECTORY_TEST_DATABASE_URL'];
  if (url == null) {
    test(
      'durable PostgreSQL scheduling',
      () {},
      skip: 'Set DIRECTORY_TEST_DATABASE_URL to an isolated database ending in _test',
    );
    return;
  }
  if (!Uri.parse(url).path.endsWith('_test')) {
    throw StateError('Tests require an isolated _test database');
  }
  final db = Pool.withUrl(url);
  late DirectoryService api;
  const key = 'synthetic-source-key', admin = 'synthetic-admin-key';
  DirectoryService service() => DirectoryService(
    db,
    adminKey: admin,
    sourceKeys: {'synthetic': key, 'other': 'different-source-key'},
  );
  Future<Response> call(
    String path, {
    String method = 'POST',
    String token = key,
    Json? body,
  }) => api.call(
    Request(
      method,
      Uri.parse('http://localhost/$path'),
      headers: {'authorization': 'Bearer $token'},
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Json> decode(Response r) async =>
      jsonDecode(await r.readAsString()) as Json;
  Future<Json> claim() async =>
      (await decode(await call('internal/sources/synthetic/claim')))['job']
          as Json;
  Future<Response> complete(Json job, Json payload) => call(
    'internal/sources/synthetic/jobs/${job['jobId']}',
    body: {'action': 'complete', 'lease': job['lease'], 'result': payload},
  );
  Future<void> refresh() async {
    expect(
      (await call(
        'internal/sources/synthetic/refresh',
        token: admin,
      )).statusCode,
      200,
    );
  }

  setUp(() async {
    api = service();
    await api.migrate([config('synthetic'), config('other')], seed());
    await db.execute(
      'TRUNCATE directory_outbox,source_items,jobs,sources,catalog CASCADE',
    );
    await api.migrate([config('synthetic'), config('other')], seed());
  });
  tearDownAll(db.close);
  test(
    'source credentials cannot claim another source or change settings',
    () async {
      expect((await call('internal/sources/other/claim')).statusCode, 401);
      expect(
        (await call(
          'internal/sources/synthetic/settings',
          method: 'PATCH',
          body: {'enabled': false, 'intervalSeconds': 86400},
        )).statusCode,
        401,
      );
      expect(
        (await call(
          'v1/directory/catalog',
          method: 'GET',
          token: '',
        )).statusCode,
        200,
      );
    },
  );
  test('concurrent claims serialize one job and exact completion replay emits one event', () async {
    final responses = await Future.wait([
      call('internal/sources/synthetic/claim'),
      call('internal/sources/synthetic/claim'),
    ]);
    final jobs = await Future.wait(responses.map(decode));
    expect(jobs.where((j) => j['job'] != null), hasLength(1));
    final job = jobs.singleWhere((j) => j['job'] != null)['job'] as Json,
        payload = result();
    expect((await complete(job, payload)).statusCode, 200);
    expect((await complete(job, payload)).statusCode, 200);
    expect(
      (await db.execute('SELECT count(*) FROM directory_outbox')).single[0],
      1,
    );
    final catalog = await decode(
      await call('v1/directory/catalog', method: 'GET'),
    );
    expect((catalog['branches'] as List).single['id'], 'synthetic-old');
    expect(
      (await decode(await call('internal/sources/synthetic/claim')))['job'],
      isNull,
    );
    payload['items'] = [];
    expect((await complete(job, payload)).statusCode, 409);
  });
  test('expired leases survive restart and fence out an old worker', () async {
    final first = await claim();
    await db.execute(
      "UPDATE jobs SET lease_until=CURRENT_TIMESTAMP-interval '1 second'",
    );
    api = service();
    await api.migrate([config('synthetic'), config('other')], seed());
    final next = await claim();
    expect(next['jobId'], first['jobId']);
    expect(next['lease'], isNot(first['lease']));
    expect((await complete(first, result())).statusCode, 409);
    expect((await complete(next, result())).statusCode, 200);
  });
  test(
    'HTTP/markup failure preserves last good snapshot and defers retry',
    () async {
      final job = await claim();
      expect(
        (await call(
          'internal/sources/synthetic/jobs/${job['jobId']}',
          body: {'action': 'fail', 'lease': job['lease'], 'error': 'http_403'},
        )).statusCode,
        200,
      );
      final catalog = await decode(
        await call('v1/directory/catalog', method: 'GET'),
      );
      expect(catalog['version'], 'seed');
      expect(
        (await decode(await call('internal/sources/synthetic/claim')))['job'],
        isNull,
      );
      final sources = await decode(
        await call('v1/directory/sources', method: 'GET'),
      );
      expect(
        (sources['sources'] as List).singleWhere(
          (s) => s['id'] == 'synthetic',
        )['lastError'],
        'http_403',
      );
      await refresh();
      expect(await claim(), contains('jobId'));
    },
  );
  test(
    'bad import cannot replace snapshot or erase previously observed items',
    () async {
      var job = await claim();
      expect((await complete(job, result())).statusCode, 200);
      await refresh();
      job = await claim();
      final partial = result()
        ..['items'] = []
        ..['catalogueStatus'] = [
          {
            'url': 'https://example.org/catalogue',
            'city': 'spb',
            'status': 'failed',
            'pages': 1,
            'items': 0,
            'error': 'markup_changed',
          },
        ];
      expect((await complete(job, partial)).statusCode, 200);
      final stored = await decode(
        await call(
          'internal/sources/synthetic/items',
          method: 'GET',
          token: admin,
        ),
      );
      expect(stored['items'], hasLength(1));
      await refresh();
      job = await claim();
      final invalid = result();
      (invalid['branches'] as List).clear();
      expect((await complete(job, invalid)).statusCode, 400);
      expect(
        (await db.execute('SELECT count(*) FROM directory_outbox')).single[0],
        2,
      );
    },
  );
  test(
    'disabled schedule is durable and health checks database availability',
    () async {
      expect(
        (await call(
          'internal/sources/synthetic/settings',
          method: 'PATCH',
          token: admin,
          body: {'enabled': false, 'intervalSeconds': 7200},
        )).statusCode,
        200,
      );
      api = service();
      await api.migrate([config('synthetic'), config('other')], seed());
      expect(
        (await decode(await call('internal/sources/synthetic/claim')))['job'],
        isNull,
      );
      expect((await call('health', method: 'GET')).statusCode, 200);
    },
  );
}
