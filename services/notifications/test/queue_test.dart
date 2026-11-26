import 'dart:convert';
import 'dart:io';

import 'package:notifications_service/notifications_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final file = File('../../infra/documents/.env');
  final configured = Platform.environment['NOTIFICATIONS_TEST_DATABASE_URL'];
  if (configured == null && !file.existsSync()) {
    test(
      'PostgreSQL prerequisites',
      () {},
      skip: 'Initialize local PostgreSQL and notifications_tests',
    );
    return;
  }
  final env = file.existsSync()
      ? {
          for (final l in file.readAsLinesSync())
            l.split('=').first: l.substring(l.indexOf('=') + 1),
        }
      : <String, String>{};
  final db = Pool.withUrl(
    configured ??
        'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/notifications_tests?sslmode=disable',
  );
  final api = NotificationsService(
    db,
    publisherKey: 'publisher',
    adminKey: 'admin',
    channelKeys: {'telegram': 'tg', 'vk': 'vk', 'max': 'max'},
  );
  Future<Response> request(
    String path, {
    Map<String, Object?>? data,
    String method = 'POST',
    String? role,
    String? key,
  }) => api.call(
    Request(
      method,
      Uri.parse('http://localhost/$path'),
      headers: {if (role != null) 'x-notifications-$role-key': key!},
      body: data == null ? null : jsonEncode({'schemaVersion': 1, ...data}),
    ),
  );
  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  Future<Response> bind({
    String owner = 'owner',
    String channel = 'telegram',
    String id = 'binding',
    bool enabled = true,
    String key = 'admin',
  }) => request(
    'internal/bindings',
    role: 'admin',
    key: key,
    data: {
      'bindingId': id,
      'ownerId': owner,
      'channel': channel,
      'enabled': enabled,
      'simulationOnly': true,
    },
  );
  Map<String, Object?> intent({
    String id = 'event',
    String owner = 'owner',
    String channel = 'telegram',
    String binding = 'binding',
  }) => {
    'notificationId': id,
    'ownerId': owner,
    'channel': channel,
    'bindingId': binding,
    'template': 'processing_ready',
    'locale': 'ru',
  };
  Future<Response> enqueue([Map<String, Object?>? data]) => request(
    'internal/notifications',
    role: 'publisher',
    key: 'publisher',
    data: data ?? intent(),
  );
  Future<Response> claim({String channel = 'telegram', String key = 'tg'}) =>
      request(
        'internal/channels/$channel/claim',
        role: 'worker',
        key: key,
        data: {},
      );
  Future<Map<String, dynamic>> job() async =>
      (await json(await claim()))['job'] as Map<String, dynamic>;
  Future<Response> result(
    Map<String, dynamic> job, {
    String outcome = 'simulated',
    String code = 'dry_run',
  }) => request(
    'internal/channels/telegram/result',
    role: 'worker',
    key: 'tg',
    data: {
      'notificationId': job['notificationId'],
      'attemptId': job['attemptId'],
      'outcome': outcome,
      'code': code,
      'retryAfterSeconds': 30,
    },
  );
  Future<Map<String, dynamic>> status() async => json(
    await request(
      'internal/notifications/event',
      method: 'GET',
      role: 'publisher',
      key: 'publisher',
    ),
  );
  setUpAll(api.migrate);
  tearDownAll(db.close);
  setUp(() async {
    await db.execute(
      'TRUNCATE notification_outbox,receipts,notifications,bindings',
    );
    expect((await bind()).statusCode, 200);
  });

  test('roles, owner and channel binding scopes are enforced', () async {
    expect((await bind(key: 'publisher')).statusCode, 401);
    expect((await enqueue(intent(owner: 'other'))).statusCode, 403);
    expect((await enqueue(intent(channel: 'vk'))).statusCode, 403);
    expect((await bind(owner: 'other')).statusCode, 409);
    expect((await claim(channel: 'vk', key: 'tg')).statusCode, 401);
    expect(
      (await request(
        'internal/notifications',
        role: 'publisher',
        key: 'admin',
        data: intent(),
      )).statusCode,
      401,
    );
    expect((await request('webhooks/telegram', data: {})).statusCode, 503);
  });
  test(
    'schema rejects arbitrary content, external recipients and live bindings',
    () async {
      expect(
        (await enqueue({...intent(), 'text': 'synthetic medical data'}))
            .statusCode,
        400,
      );
      expect((await enqueue({...intent(), 'chatId': '1234'})).statusCode, 400);
      expect(
        (await enqueue({...intent(), 'schemaVersion': 2})).statusCode,
        400,
      );
      expect(
        (await request(
          'internal/bindings',
          role: 'admin',
          key: 'admin',
          data: {
            'bindingId': 'live',
            'ownerId': 'owner',
            'channel': 'vk',
            'enabled': true,
            'simulationOnly': false,
          },
        )).statusCode,
        400,
      );
    },
  );
  test('concurrent enqueue and lost response replay have one intent and outbox event', () async {
    final replies = await Future.wait([enqueue(), enqueue()]);
    expect(replies.map((r) => r.statusCode), everyElement(200));
    expect(
      (await db.execute('SELECT count(*) FROM notifications')).single[0],
      1,
    );
    expect(
      (await db.execute('SELECT count(*) FROM notification_outbox')).single[0],
      1,
    );
    expect((await enqueue({...intent(), 'locale': 'en'})).statusCode, 409);
  });
  test(
    'parallel claims fence one attempt; simulation receipt is idempotent',
    () async {
      await enqueue();
      final pair = await Future.wait([claim(), claim()]);
      final jobs = await Future.wait(pair.map(json));
      expect(jobs.where((j) => j['job'] != null).length, 1);
      final leased =
          jobs.singleWhere((j) => j['job'] != null)['job']
              as Map<String, dynamic>;
      final done = await json(await result(leased));
      expect(done['state'], 'simulated');
      expect(done['attempts'], 1);
      expect(await json(await result(leased)), done);
      expect(
        (await result(
          leased,
          outcome: 'unknown',
          code: 'ambiguous_result',
        )).statusCode,
        409,
      );
      expect(
        (await db.execute('SELECT count(*) FROM notification_outbox'))
            .single[0],
        3,
      );
      expect((await json(await claim()))['job'], null);
    },
  );
  test(
    'expired lease after process restart becomes unknown and never requeues',
    () async {
      await enqueue();
      final leased = await job();
      await db.execute(
        "UPDATE notifications SET lease_until=CURRENT_TIMESTAMP-interval '1 second'",
      );
      final restarted = NotificationsService(
        db,
        publisherKey: 'publisher',
        adminKey: 'admin',
        channelKeys: {'telegram': 'tg'},
      );
      await restarted.migrate();
      expect((await result(leased)).statusCode, 409);
      expect((await json(await claim()))['job'], null);
      expect((await status())['state'], 'unknown');
      expect((await status())['code'], 'lease_expired');
      expect((await json(await claim()))['job'], null);
    },
  );
  test('ambiguous result is terminal; cannot be labelled as retry', () async {
    await enqueue();
    final leased = await job();
    expect(
      (await result(
        leased,
        outcome: 'retry',
        code: 'ambiguous_result',
      )).statusCode,
      400,
    );
    expect(
      (await json(
        await result(leased, outcome: 'unknown', code: 'ambiguous_result'),
      ))['state'],
      'unknown',
    );
    expect((await json(await claim()))['job'], null);
  });
  test(
    'safe retries respect delay, stale fencing and maximum attempts',
    () async {
      await enqueue();
      Map<String, dynamic>? previous;
      for (var n = 1; n <= 5; n++) {
        final leased = await job();
        if (previous != null) {
          expect((await result(previous)).statusCode, 409);
        }
        final r = await json(
          await result(leased, outcome: 'retry', code: 'provider_rate_limited'),
        );
        expect(r['state'], n == 5 ? 'failed' : 'retry');
        expect(r['attempts'], n);
        expect((await json(await claim()))['job'], null);
        await db.execute(
          "UPDATE notifications SET next_at=CURRENT_TIMESTAMP-interval '1 second'",
        );
        previous = leased;
      }
      expect((await json(await claim()))['job'], null);
      expect((await status())['code'], 'retry_exhausted');
    },
  );
  test(
    'revoked and expired bindings do not dispatch; revocation fences result',
    () async {
      await enqueue();
      await bind(enabled: false);
      expect((await json(await claim()))['job'], null);
      expect((await status())['state'], 'cancelled');
      await bind();
      await enqueue(intent(id: 'second'));
      final leased = await job();
      await bind(enabled: false);
      expect((await json(await result(leased)))['state'], 'cancelled');
      await bind();
      await enqueue(intent(id: 'third'));
      await db.execute(
        "UPDATE notifications SET expires_at=CURRENT_TIMESTAMP-interval '1 second' WHERE notification_id='third'",
      );
      expect((await json(await claim()))['job'], null);
    },
  );
  test('outbox failure rolls back intent and receipt transitions', () async {
    Future<void> trigger() async {
      await db.execute(
        "CREATE OR REPLACE FUNCTION fail_notice() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RAISE EXCEPTION ''synthetic failure''; END'",
      );
      await db.execute(
        'CREATE TRIGGER fail_notice BEFORE INSERT ON notification_outbox FOR EACH ROW EXECUTE FUNCTION fail_notice()',
      );
    }

    Future<void> clear() async {
      await db.execute('DROP TRIGGER fail_notice ON notification_outbox');
      await db.execute('DROP FUNCTION fail_notice()');
    }

    await trigger();
    try {
      expect((await enqueue()).statusCode, 503);
      expect(
        (await db.execute('SELECT count(*) FROM notifications')).single[0],
        0,
      );
    } finally {
      await clear();
    }
    await enqueue();
    final leased = await job();
    await trigger();
    try {
      expect((await result(leased)).statusCode, 503);
      expect((await status())['state'], 'leased');
      expect((await db.execute('SELECT count(*) FROM receipts')).single[0], 0);
    } finally {
      await clear();
    }
    expect((await json(await result(leased)))['state'], 'simulated');
  });
}
