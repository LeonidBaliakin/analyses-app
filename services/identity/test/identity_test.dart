import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:identity_service/identity_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('production password cost and independent salts', () async {
    const passwords = Passwords();
    expect(passwords.iterations, 600000);
    final a = nonce(), b = nonce();
    final hash = await passwords.hash('synthetic long password', a);
    expect(hash, await passwords.hash('synthetic long password', a));
    expect(hash, isNot(await passwords.hash('synthetic long password', b)));
  });
  final file = File('../../infra/documents/.env');
  if (!file.existsSync()) {
    test('PostgreSQL', () {}, skip: 'Initialize local Documents PostgreSQL');
    return;
  }
  final env = {
    for (final line in file.readAsLinesSync())
      line.split('=').first: line.substring(line.indexOf('=') + 1),
  };
  // Only the disposable *_tests database is ever truncated.
  final db = Pool.withUrl(
    'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/identity_tests?sslmode=disable',
  );
  late IdentityService api;
  final mail = <String, String>{};
  const password = 'synthetic initial password';
  Future<Response> request(
    String action, {
    String method = 'POST',
    Map<String, Object?>? body,
    String? token,
    String? cookie,
    bool csrf = true,
  }) => api.call(
    Request(
      method,
      Uri.parse('http://localhost/v1/auth/$action'),
      headers: {
        'content-type': 'application/json',
        'x-identity-service-key': 'test-service-key',
        if (csrf) 'x-app-request': '1',
        if (token != null) 'authorization': 'Bearer $token',
        'cookie': ?cookie,
      },
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  Future<String> challenge(String email, {bool recovery = false}) async {
    final response = await request(
      'challenges',
      body: {'email': email, 'purpose': recovery ? 'recover' : 'register'},
    );
    expect(response.statusCode, 202);
    await api.deliverOne((email, purpose, code) async {
      mail[email] = code;
    });
    return (await json(response))['challengeId'] as String;
  }

  Future<Map<String, dynamic>> register(
    String email, {
    String transport = 'bearer',
  }) async {
    final id = await challenge(email);
    final response = await request(
      'register',
      body: {
        'challengeId': id,
        'code': mail[email],
        'password': password,
        'deviceLabel': 'Synthetic phone',
        'transport': transport,
      },
    );
    expect(response.statusCode, 200);
    return json(response);
  }

  setUpAll(() async {
    await IdentityService(
      db,
      serviceKey: 'test-service-key',
      mailKey: SecretKey(List.filled(32, 7)),
    ).migrate();
  });
  tearDownAll(() => db.close());
  setUp(() async {
    await db.execute(
      'TRUNCATE mail_outbox,challenges,sessions,users,auth_limits CASCADE',
    );
    api = IdentityService(
      db,
      serviceKey: 'test-service-key',
      mailKey: SecretKey(List.filled(32, 7)),
      passwords: const Passwords(iterations: 1000),
    );
    mail.clear();
  });
  test('email verification, race/replay, no password or credential stored in plaintext', () async {
    final id = await challenge('synthetic@example.test');
    expect((await db.execute('SELECT count(*) FROM users')).single[0], 0);
    final body = {
      'challengeId': id,
      'code': mail['synthetic@example.test'],
      'password': password,
      'deviceLabel': 'Phone',
      'transport': 'bearer',
    };
    final replies = await Future.wait([
      request('register', body: body),
      request('register', body: body),
    ]);
    expect(replies.map((r) => r.statusCode).toList()..sort(), [200, 400]);
    expect((await db.execute('SELECT count(*) FROM users')).single[0], 1);
    final user = (await db.execute('SELECT * FROM users')).single.toColumnMap();
    expect(user.values, isNot(contains(password)));
    final session = (await json(
      replies.firstWhere((r) => r.statusCode == 200),
    ));
    expect(
      (await db.execute('SELECT token_hash FROM sessions')).single[0],
      digest(session['token'] as String),
    );
    expect(
      (await request(
        'session',
        method: 'GET',
        token: session['token'] as String,
      )).statusCode,
      200,
    );
  });
  test('second device, owner-scoped revocation and immediate logout', () async {
    final first = await register('synthetic@example.test');
    final second = await json(
      await request(
        'login',
        body: {
          'email': 'SYNTHETIC@example.test',
          'password': password,
          'deviceLabel': 'Tablet',
          'transport': 'bearer',
        },
      ),
    );
    expect(second['ownerId'], first['ownerId']);
    expect(second['token'], isNot(first['token']));
    final other = await register('other@example.test');
    await request(
      'sessions/${second['sessionId']}/revoke',
      token: other['token'] as String,
      body: {},
    );
    expect(
      (await request(
        'session',
        method: 'GET',
        token: second['token'] as String,
      )).statusCode,
      200,
    );
    await request(
      'sessions/${second['sessionId']}/revoke',
      token: first['token'] as String,
      body: {},
    );
    expect(
      (await request(
        'session',
        method: 'GET',
        token: second['token'] as String,
      )).statusCode,
      401,
    );
    expect(
      (await request(
        'session',
        method: 'GET',
        token: first['token'] as String,
      )).statusCode,
      200,
    );
    await request('logout', token: first['token'] as String, body: {});
    expect(
      (await request(
        'session',
        method: 'GET',
        token: first['token'] as String,
      )).statusCode,
      401,
    );
  });
  test('recovery revokes all old sessions, is single-use, does not log in automatically', () async {
    final first = await register('synthetic@example.test');
    final id = await challenge('synthetic@example.test', recovery: true);
    final body = {
      'challengeId': id,
      'code': mail['synthetic@example.test'],
      'password': 'synthetic replacement password',
    };
    expect((await request('recover', body: body)).statusCode, 200);
    expect((await request('recover', body: body)).statusCode, 400);
    expect(
      (await request(
        'session',
        method: 'GET',
        token: first['token'] as String,
      )).statusCode,
      401,
    );
    expect(
      (await request(
        'login',
        body: {
          'email': 'synthetic@example.test',
          'password': password,
          'deviceLabel': 'Phone',
        },
      )).statusCode,
      401,
    );
    expect(
      (await request(
        'login',
        body: {
          'email': 'synthetic@example.test',
          'password': body['password'],
          'deviceLabel': 'Phone',
          'transport': 'bearer',
        },
      )).statusCode,
      200,
    );
  });
  test('expired code and five guesses cannot register, generic response for unknown recovery', () async {
    final id = await challenge('synthetic@example.test');
    final correct = mail['synthetic@example.test'];
    for (var i = 0; i < 5; i++) {
      expect(
        (await request(
          'register',
          body: {
            'challengeId': id,
            'code': correct == '00000000' ? '11111111' : '00000000',
            'password': password,
            'deviceLabel': 'Phone',
          },
        )).statusCode,
        400,
      );
    }
    expect(
      (await request(
        'register',
        body: {
          'challengeId': id,
          'code': correct,
          'password': password,
          'deviceLabel': 'Phone',
        },
      )).statusCode,
      400,
    );
    final expired = await challenge('expired@example.test');
    await db.execute(
      Sql.named(
        "UPDATE challenges SET expires_at=CURRENT_TIMESTAMP-interval '1 second' WHERE challenge_id=@i",
      ),
      parameters: {'i': expired},
    );
    expect(
      (await request(
        'register',
        body: {
          'challengeId': expired,
          'code': mail['expired@example.test'],
          'password': password,
          'deviceLabel': 'Phone',
        },
      )).statusCode,
      400,
    );
    final response = await request(
      'challenges',
      body: {'email': 'unknown@example.test', 'purpose': 'recover'},
    );
    expect(response.statusCode, 202);
    expect((await json(response)).keys.toSet(), {
      'schemaVersion',
      'challengeId',
    });
  });
  test('encrypted transactional outbox, retry after SMTP failure and database restart', () async {
    final response = await request(
      'challenges',
      body: {'email': 'synthetic@example.test', 'purpose': 'register'},
    );
    expect(response.statusCode, 202);
    final sealed =
        (await db.execute('SELECT sealed FROM mail_outbox')).single[0]
            as String;
    expect(sealed, isNot(contains('synthetic@example.test')));
    await api.deliverOne((_, _, _) async {
      throw StateError('synthetic smtp failure');
    });
    expect(
      (await db.execute('SELECT delivered,attempts FROM mail_outbox')).single,
      [false, 1],
    );
    await db.execute('UPDATE mail_outbox SET next_at=CURRENT_TIMESTAMP');
    final restarted = IdentityService(
      db,
      serviceKey: 'test-service-key',
      mailKey: SecretKey(List.filled(32, 7)),
    );
    await restarted.deliverOne((email, _, code) async {
      mail[email] = code;
    });
    expect(mail['synthetic@example.test'], hasLength(8));
    expect(
      (await db.execute('SELECT delivered,sealed FROM mail_outbox')).single,
      [true, ''],
    );
    await db.execute(
      "CREATE OR REPLACE FUNCTION fail_auth_mail() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RAISE EXCEPTION ''synthetic outbox failure''; END'",
    );
    await db.execute(
      'CREATE TRIGGER fail_mail BEFORE INSERT ON mail_outbox FOR EACH ROW EXECUTE FUNCTION fail_auth_mail()',
    );
    try {
      expect(
        (await request(
          'challenges',
          body: {'email': 'rollback@example.test', 'purpose': 'register'},
        )).statusCode,
        503,
      );
      expect(
        (await db.execute(
          "SELECT count(*) FROM challenges WHERE email='rollback@example.test'",
        )).single[0],
        0,
      );
    } finally {
      await db.execute('DROP TRIGGER fail_mail ON mail_outbox');
      await db.execute('DROP FUNCTION fail_auth_mail()');
    }
  });
  test('cookie session, CSRF, internal validation secret and expiry', () async {
    final id = await challenge('synthetic@example.test');
    final response = await request(
      'register',
      body: {
        'challengeId': id,
        'code': mail['synthetic@example.test'],
        'password': password,
        'deviceLabel': 'Web',
        'transport': 'cookie',
      },
    );
    final cookie = response.headers['set-cookie']!;
    expect(cookie, contains('HttpOnly'));
    expect(cookie, contains('Secure'));
    expect(cookie, contains('SameSite=Lax'));
    expect((await json(response)).containsKey('token'), false);
    final credential = cookie.split(';').first;
    expect(
      (await api.call(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/auth/session'),
          headers: {
            'cookie': credential,
            'x-identity-service-key': 'test-service-key',
            'x-account-owner': 'different-owner',
          },
        ),
      )).statusCode,
      401,
    );
    expect(
      (await request('session', method: 'GET', cookie: credential)).statusCode,
      200,
    );
    expect(
      (await request(
        'logout',
        cookie: credential,
        csrf: false,
        body: {},
      )).statusCode,
      403,
    );
    expect(
      (await api.call(
        Request(
          'GET',
          Uri.parse('http://localhost/internal/session'),
          headers: {'cookie': credential},
        ),
      )).statusCode,
      401,
    );
    expect(
      (await api.call(
        Request(
          'GET',
          Uri.parse('http://localhost/internal/session'),
          headers: {
            'cookie': credential,
            'x-identity-service-key': 'test-service-key',
          },
        ),
      )).statusCode,
      200,
    );
    await db.execute(
      "UPDATE sessions SET expires_at=CURRENT_TIMESTAMP-interval '1 second'",
    );
    expect(
      (await request('session', method: 'GET', cookie: credential)).statusCode,
      401,
    );
  });
  test('mail and password guesses have persistent rate limits', () async {
    for (var i = 0; i < 4; i++) {
      expect(
        (await request(
          'challenges',
          body: {'email': 'synthetic@example.test', 'purpose': 'register'},
        )).statusCode,
        202,
      );
    }
    expect(
      (await request(
        'challenges',
        body: {'email': 'synthetic@example.test', 'purpose': 'recover'},
      )).statusCode,
      429,
    );
    for (var i = 0; i < 12; i++) {
      expect(
        (await request(
          'login',
          body: {
            'email': 'unknown@example.test',
            'password': password,
            'deviceLabel': 'Phone',
          },
        )).statusCode,
        401,
      );
    }
    expect(
      (await request(
        'login',
        body: {
          'email': 'unknown@example.test',
          'password': password,
          'deviceLabel': 'Phone',
        },
      )).statusCode,
      429,
    );
  });
}
