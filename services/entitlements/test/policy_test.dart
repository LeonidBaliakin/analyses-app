import 'dart:convert';
import 'dart:io';

import 'package:entitlements_service/entitlements_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final file = File('../../infra/documents/.env');
  if (!file.existsSync()) {
    test('PostgreSQL', () {}, skip: 'Initialize local stack');
    return;
  }
  final env = {
    for (final l in file.readAsLinesSync())
      l.split('=').first: l.substring(l.indexOf('=') + 1),
  };
  final db = Pool.withUrl(
    'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/entitlements_tests?sslmode=disable',
  );
  final api = EntitlementsService(
    db,
    serviceKey: 'reader-secret',
    adminKey: 'admin-secret',
  );
  Future<Response> get(String owner, {String key = 'reader-secret'}) =>
      api.call(
        Request(
          'GET',
          Uri.parse('http://localhost/internal/policies/$owner'),
          headers: {'x-cloud-service-key': key},
        ),
      );
  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  Future<Response> grant(
    Map<String, dynamic> policy, {
    String owner = 'a',
    String id = 'grant1',
    int base = 1,
    String key = 'admin-secret',
  }) => api.call(
    Request(
      'PUT',
      Uri.parse('http://localhost/internal/policies/$owner'),
      headers: {'x-cloud-admin-key': key},
      body: jsonEncode({
        'operationId': id,
        'baseRevision': base,
        'policy': policy,
      }),
    ),
  );
  setUpAll(api.migrate);
  tearDownAll(db.close);
  setUp(() async {
    await db.execute('TRUNCATE policies,grants,policy_outbox');
  });
  test(
    'read key cannot grant, independent flags and server-side expiry',
    () async {
      expect((await get('a', key: 'wrong')).statusCode, 401);
      final policy = await json(await get('a'));
      expect(policy['revision'], 1);
      expect((await grant(policy, key: 'reader-secret')).statusCode, 401);
      final next = {
        ...policy,
        'syncEnabled': false,
        'storageEnabled': true,
        'processingEnabled': false,
        'validUntil': '2000-01-01T00:00:00Z',
      };
      expect((await grant(next)).statusCode, 200);
      final expired = await json(await get('a'));
      expect(expired['active'], false);
      expect(expired['storageEnabled'], true);
      expect((await json(await get('b')))['syncEnabled'], true);
    },
  );
  test(
    'grant replay/lost response, changed payload and stale revision',
    () async {
      final p = await json(await get('a'));
      final pair = await Future.wait([
        grant({...p, 'recordLimit': 0}),
        grant({...p, 'recordLimit': 0}),
      ]);
      expect(pair.map((r) => r.statusCode), everyElement(200));
      expect(
        (await db.execute('SELECT count(*) FROM policy_outbox')).single[0],
        1,
      );
      expect((await grant({...p, 'recordLimit': 1})).statusCode, 409);
      expect((await grant(p, id: 'stale')).statusCode, 409);
      final replay = await json(await grant({...p, 'recordLimit': 0}));
      expect(replay['revision'], 2);
      expect((await grant(p, owner: 'b')).statusCode, 409);
    },
  );
  test('outbox failure rolls back policy and receipt together', () async {
    final p = await json(await get('a'));
    await db.execute(
      "CREATE OR REPLACE FUNCTION fail_policy() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RAISE EXCEPTION ''synthetic outbox''; END'",
    );
    await db.execute(
      'CREATE TRIGGER fail_policy BEFORE INSERT ON policy_outbox FOR EACH ROW EXECUTE FUNCTION fail_policy()',
    );
    try {
      expect((await grant({...p, 'storageLimitBytes': 0})).statusCode, 503);
      expect((await json(await get('a')))['revision'], 1);
      expect((await db.execute('SELECT count(*) FROM grants')).single[0], 0);
    } finally {
      await db.execute('DROP TRIGGER fail_policy ON policy_outbox');
      await db.execute('DROP FUNCTION fail_policy()');
    }
  });
}
