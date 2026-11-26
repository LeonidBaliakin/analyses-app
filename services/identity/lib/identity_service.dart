import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

String nonce([int bytes = 32]) => base64Url
    .encode(List.generate(bytes, (_) => Random.secure().nextInt(256)))
    .replaceAll('=', '');
String digest(String value) =>
    crypto.sha256.convert(utf8.encode(value)).toString();
bool same(String a, String b) {
  var diff = a.length ^ b.length;
  for (var i = 0; i < a.length && i < b.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

class AuthError implements Exception {
  const AuthError(this.status, this.code);
  final int status;
  final String code;
}

/// Only hashes and independently salted password verifiers leave this service.
class Passwords {
  const Passwords({this.iterations = 600000});
  final int iterations;
  Future<String> hash(String password, String salt) {
    final count = iterations;
    return Isolate.run(() async {
      final key =
          await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: count,
            bits: 256,
          ).deriveKeyFromPassword(
            password: password,
            nonce: base64Url.decode(base64Url.normalize(salt)),
          );
      return base64Url.encode(await key.extractBytes());
    });
  }
}

typedef SendCode = Future<void> Function(
  String email,
  String purpose,
  String code,
);

class IdentityService {
  IdentityService(
    this.db, {
    required this.serviceKey,
    required this.mailKey,
    this.secureCookie = true,
    this.passwords = const Passwords(),
  });
  final Pool db;
  final String serviceKey;
  final SecretKey mailKey;
  final bool secureCookie;
  final Passwords passwords;
  int _hashing = 0;
  Future<String> _hash(String password, String salt) async {
    if (_hashing >= 4) throw const AuthError(429, 'rate_limited');
    _hashing++;
    try {
      return await passwords.hash(password, salt);
    } finally {
      _hashing--;
    }
  }

  String get cookieName =>
      secureCookie ? '__Host-analyses_session' : 'analyses_session';

  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786208)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS identity_schema(id int PRIMARY KEY CHECK(id=1),version int NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO identity_schema VALUES(1,1) ON CONFLICT DO NOTHING',
    );
    if ((await tx.execute('SELECT version FROM identity_schema')).single[0] !=
        1) {
      throw StateError('Unsupported identity schema');
    }
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS users(owner_id text PRIMARY KEY,email text NOT NULL UNIQUE,salt text NOT NULL,password_hash text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
      '''CREATE TABLE IF NOT EXISTS sessions(session_id text PRIMARY KEY,owner_id text NOT NULL REFERENCES users(owner_id),token_hash text NOT NULL UNIQUE,device_label text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,expires_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP+interval '30 days',revoked boolean NOT NULL DEFAULT false)''',
      '''CREATE TABLE IF NOT EXISTS challenges(challenge_id text PRIMARY KEY,email text NOT NULL,purpose text NOT NULL,code_hash text NOT NULL,attempts int NOT NULL DEFAULT 0,consumed boolean NOT NULL DEFAULT false,expires_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP+interval '15 minutes')''',
      '''CREATE TABLE IF NOT EXISTS auth_limits(key text PRIMARY KEY,window_start timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,n int NOT NULL DEFAULT 1)''',
      '''CREATE TABLE IF NOT EXISTS mail_outbox(id text PRIMARY KEY,challenge_id text NOT NULL REFERENCES challenges(challenge_id),sealed text NOT NULL,attempts int NOT NULL DEFAULT 0,next_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,delivered boolean NOT NULL DEFAULT false)''',
      'CREATE INDEX IF NOT EXISTS session_owner ON sessions(owner_id)',
      'CREATE INDEX IF NOT EXISTS pending_mail ON mail_outbox(next_at) WHERE NOT delivered',
    ]) {
      await tx.execute(sql);
    }
  });

  Future<void> _limit(String key, int max) async {
    final rows = await db.execute(
      Sql.named(
        '''INSERT INTO auth_limits(key) VALUES(@k)
      ON CONFLICT(key) DO UPDATE SET
      n=CASE WHEN auth_limits.window_start < CURRENT_TIMESTAMP-interval '15 minutes' THEN 1 ELSE auth_limits.n+1 END,
      window_start=CASE WHEN auth_limits.window_start < CURRENT_TIMESTAMP-interval '15 minutes' THEN CURRENT_TIMESTAMP ELSE auth_limits.window_start END RETURNING n''',
      ),
      parameters: {'k': digest(key)},
    );
    if ((rows.single[0] as int) > max) {
      throw const AuthError(429, 'rate_limited');
    }
  }

  String _email(Object? value) {
    if (value is! String ||
        value.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      throw const AuthError(400, 'email');
    }
    return value.trim().toLowerCase();
  }

  String _password(Object? value) {
    if (value is! String ||
        value.runes.length < 15 ||
        value.runes.length > 128 ||
        utf8.encode(value).length > 512) {
      throw const AuthError(400, 'password');
    }
    return value;
  }

  String _label(Object? value) {
    if (value is! String ||
        value.trim().isEmpty ||
        value.length > 80 ||
        value.runes.any((n) => n < 32)) {
      throw const AuthError(400, 'device');
    }
    return value.trim();
  }

  Future<Map<String, dynamic>> _body(Request req) async {
    if (!(req.headers['content-type'] ?? '').startsWith('application/json')) {
      throw const AuthError(415, 'content_type');
    }
    final bytes = <int>[];
    await for (final chunk in req.read().timeout(const Duration(seconds: 15))) {
      if (bytes.length + chunk.length > 8192) {
        throw const AuthError(413, 'too_large');
      }
      bytes.addAll(chunk);
    }
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Response _json(int status, Map<String, Object?> value, {String? cookie}) =>
      Response(
        status,
        body: jsonEncode({'schemaVersion': 1, ...value}),
        headers: {
          'content-type': 'application/json',
          'cache-control': 'no-store',
          'x-content-type-options': 'nosniff',
          'set-cookie': ?cookie,
        },
      );
  String? credential(Request req) {
    final authorization = req.headers['authorization'];
    if (authorization != null) {
      if (!authorization.startsWith('Bearer ') || authorization.length > 512) {
        return null;
      }
      return authorization.substring(7);
    }
    for (final part in (req.headers['cookie'] ?? '').split(';')) {
      final p = part.trim();
      if (p.startsWith('$cookieName=')) {
        return p.substring(cookieName.length + 1);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> actor(Request req) async {
    final token = credential(req);
    if (token == null || token.length < 32 || token.length > 128) {
      throw const AuthError(401, 'unauthorized');
    }
    final rows = await db.execute(
      Sql.named(
        '''SELECT s.*,u.email FROM sessions s JOIN users u USING(owner_id)
      WHERE token_hash=@h AND NOT revoked AND expires_at>CURRENT_TIMESTAMP''',
      ),
      parameters: {'h': digest(token)},
    );
    if (rows.isEmpty) throw const AuthError(401, 'unauthorized');
    if (req.headers['x-account-owner'] != null &&
        req.headers['x-account-owner'] !=
            rows.single.toColumnMap()['owner_id']) {
      throw const AuthError(401, 'unauthorized');
    }
    return rows.single.toColumnMap();
  }

  Map<String, Object?> _public(Map<String, dynamic> row) => {
    'ownerId': row['owner_id'],
    'profileId': 'local-profile',
    'email': row['email'],
    'sessionId': row['session_id'],
    'expiresAt': (row['expires_at'] as DateTime).toUtc().toIso8601String(),
  };
  String _cookie(String token, {bool clear = false}) =>
      '$cookieName=$token; Path=/; HttpOnly; SameSite=Lax; Max-Age=${clear ? 0 : 2592000}${secureCookie ? '; Secure' : ''}';
  Future<Response> _session(
    Session tx,
    String owner,
    String email,
    Map<String, dynamic> j,
  ) async {
    final token = nonce(), id = nonce(), label = _label(j['deviceLabel']);
    final rows = await tx.execute(
      Sql.named(
        '''INSERT INTO sessions(session_id,owner_id,token_hash,device_label)
      VALUES(@i,@o,@h,@d) RETURNING *''',
      ),
      parameters: {'i': id, 'o': owner, 'h': digest(token), 'd': label},
    );
    return _json(200, {
      ..._public({...rows.single.toColumnMap(), 'email': email}),
      if (j['transport'] == 'bearer') 'token': token,
    }, cookie: j['transport'] == 'bearer' ? null : _cookie(token));
  }

  Future<Response> call(Request req) async {
    try {
      if (req.method == 'GET' && req.url.path == 'health') {
        await db.execute('SELECT 1');
        return _json(200, {'status': 'ok'});
      }
      if (req.url.path == 'internal/session' && req.method == 'GET') {
        if (!same(req.headers['x-identity-service-key'] ?? '', serviceKey)) {
          throw const AuthError(401, 'unauthorized');
        }
        return _json(200, _public(await actor(req)));
      }
      final p = req.url.pathSegments;
      if (!same(req.headers['x-identity-service-key'] ?? '', serviceKey)) {
        throw const AuthError(401, 'unauthorized');
      }
      if (p.length < 3 || p[0] != 'v1' || p[1] != 'auth') {
        throw const AuthError(404, 'not_found');
      }
      if (req.method != 'GET' && req.headers['x-app-request'] != '1') {
        throw const AuthError(403, 'csrf');
      }
      final action = p[2];
      if (req.method != 'GET') {
        await _limit(
          'client:${req.headers['x-auth-client'] ?? 'unknown'}',
          150,
        );
      }
      if (req.method == 'POST' && action == 'challenges' && p.length == 3) {
        final j = await _body(req),
            email = _email(j['email']),
            purpose = j['purpose'];
        if (purpose != 'register' && purpose != 'recover') {
          throw const AuthError(400, 'purpose');
        }
        await _limit('mail:$email', 4);
        final id = nonce(),
            code = List.generate(8, (_) => Random.secure().nextInt(10)).join();
        final box = await AesGcm.with256bits().encrypt(
          utf8.encode(
            jsonEncode({'email': email, 'purpose': purpose, 'code': code}),
          ),
          secretKey: mailKey,
        );
        await db.runTx((tx) async {
          await tx.execute(
            Sql.named(
              'INSERT INTO challenges(challenge_id,email,purpose,code_hash) VALUES(@i,@e,@p,@h)',
            ),
            parameters: {
              'i': id,
              'e': email,
              'p': purpose,
              'h': digest('$id:$code'),
            },
          );
          final exists = await tx.execute(
            Sql.named('SELECT 1 FROM users WHERE email=@e'),
            parameters: {'e': email},
          );
          if ((purpose == 'register' && exists.isEmpty) ||
              (purpose == 'recover' && exists.isNotEmpty)) {
            await tx.execute(
              Sql.named(
                'INSERT INTO mail_outbox(id,challenge_id,sealed) VALUES(@i,@i,@s)',
              ),
              parameters: {'i': id, 's': base64.encode(box.concatenation())},
            );
          }
        });
        return _json(202, {'challengeId': id});
      }
      if (req.method == 'POST' &&
          ['register', 'recover'].contains(action) &&
          p.length == 3) {
        final j = await _body(req), password = _password(j['password']);
        final id = j['challengeId'], code = j['code'];
        if (id is! String ||
            id.length > 100 ||
            code is! String ||
            !RegExp(r'^\d{8}$').hasMatch(code)) {
          throw const AuthError(400, 'code');
        }
        if (action == 'register') _label(j['deviceLabel']);
        await _limit('finish:$id', 10);
        // Charge the attempt outside the transaction; rollback cannot restore guesses.
        final rows = await db.execute(
          Sql.named(
            '''UPDATE challenges SET attempts=attempts+1
          WHERE challenge_id=@i AND purpose=@p AND NOT consumed AND attempts<5 AND expires_at>CURRENT_TIMESTAMP RETURNING *''',
          ),
          parameters: {
            'i': id,
            'p': action == 'register' ? 'register' : 'recover',
          },
        );
        if (rows.isEmpty ||
            !same(
              rows.single.toColumnMap()['code_hash'] as String,
              digest('$id:$code'),
            )) {
          throw const AuthError(400, 'code');
        }
        final email = rows.single.toColumnMap()['email'] as String,
            salt = nonce();
        final hash = await _hash(password, salt);
        return await db.runTx((tx) async {
          final consumed = await tx.execute(
            Sql.named(
              '''UPDATE challenges SET consumed=true WHERE challenge_id=@i AND NOT consumed AND expires_at>CURRENT_TIMESTAMP RETURNING email''',
            ),
            parameters: {'i': id},
          );
          if (consumed.isEmpty) throw const AuthError(400, 'code');
          if (action == 'register') {
            final owner = nonce();
            final created = await tx.execute(
              Sql.named(
                '''INSERT INTO users(owner_id,email,salt,password_hash) VALUES(@o,@e,@s,@h) ON CONFLICT(email) DO NOTHING RETURNING owner_id''',
              ),
              parameters: {'o': owner, 'e': email, 's': salt, 'h': hash},
            );
            if (created.isEmpty) throw const AuthError(409, 'account_exists');
            return _session(tx, owner, email, j);
          }
          final changed = await tx.execute(
            Sql.named(
              'UPDATE users SET salt=@s,password_hash=@h WHERE email=@e RETURNING owner_id',
            ),
            parameters: {'s': salt, 'h': hash, 'e': email},
          );
          if (changed.isEmpty) throw const AuthError(400, 'code');
          final owner = changed.single[0];
          await tx.execute(
            Sql.named('UPDATE sessions SET revoked=true WHERE owner_id=@o'),
            parameters: {'o': owner},
          );
          await tx.execute(
            Sql.named('UPDATE challenges SET consumed=true WHERE email=@e'),
            parameters: {'e': email},
          );
          return _json(200, {'reset': true}, cookie: _cookie('', clear: true));
        });
      }
      if (req.method == 'POST' && action == 'login' && p.length == 3) {
        final j = await _body(req), email = _email(j['email']);
        final password = j['password'];
        if (password is! String || password.length > 512) {
          throw const AuthError(401, 'credentials');
        }
        _label(j['deviceLabel']);
        await _limit('login:$email', 12);
        final rows = await db.execute(
          Sql.named('SELECT * FROM users WHERE email=@e'),
          parameters: {'e': email},
        );
        final row = rows.isEmpty ? null : rows.single.toColumnMap();
        final salt =
            row?['salt'] as String? ?? base64Url.encode(List.filled(32, 0));
        final hash = await _hash(password, salt);
        if (row == null || !same(row['password_hash'] as String, hash)) {
          throw const AuthError(401, 'credentials');
        }
        return await db.runTx((tx) async {
          // Serialize with password recovery. A pre-reset verifier cannot issue a post-reset session.
          final current = await tx.execute(
            Sql.named(
              'SELECT password_hash FROM users WHERE owner_id=@o FOR UPDATE',
            ),
            parameters: {'o': row['owner_id']},
          );
          if (!same(current.single[0] as String, hash)) {
            throw const AuthError(401, 'credentials');
          }
          return _session(tx, row['owner_id'] as String, email, j);
        });
      }
      final current = await actor(req);
      if (req.method == 'GET' && action == 'session' && p.length == 3) {
        return _json(200, _public(current));
      }
      if (req.method == 'GET' && action == 'sessions' && p.length == 3) {
        final rows = await db.execute(
          Sql.named(
            'SELECT session_id,device_label,created_at,expires_at FROM sessions WHERE owner_id=@o AND NOT revoked AND expires_at>CURRENT_TIMESTAMP ORDER BY created_at DESC',
          ),
          parameters: {'o': current['owner_id']},
        );
        return _json(200, {
          'sessions': [
            for (final row in rows)
              {
                'sessionId': row[0],
                'deviceLabel': row[1],
                'createdAt': (row[2] as DateTime).toUtc().toIso8601String(),
                'expiresAt': (row[3] as DateTime).toUtc().toIso8601String(),
                'current': row[0] == current['session_id'],
              },
          ],
        });
      }
      if (req.method == 'POST' &&
          ['logout', 'logout-all'].contains(action) &&
          p.length == 3) {
        await db.execute(
          Sql.named(
            'UPDATE sessions SET revoked=true WHERE owner_id=@o${action == 'logout' ? ' AND session_id=@i' : ''}',
          ),
          parameters: {
            'o': current['owner_id'],
            if (action == 'logout') 'i': current['session_id'],
          },
        );
        return _json(200, {
          'signedOut': true,
        }, cookie: _cookie('', clear: true));
      }
      if (req.method == 'POST' &&
          action == 'sessions' &&
          p.length == 5 &&
          p[4] == 'revoke') {
        await db.execute(
          Sql.named(
            'UPDATE sessions SET revoked=true WHERE owner_id=@o AND session_id=@i',
          ),
          parameters: {'o': current['owner_id'], 'i': p[3]},
        );
        return _json(200, {'revoked': true});
      }
      throw const AuthError(404, 'not_found');
    } on AuthError catch (e) {
      return _json(e.status, {'error': e.code});
    } on FormatException {
      return _json(400, {'error': 'invalid_request'});
    } on TypeError {
      return _json(400, {'error': 'invalid_request'});
    } catch (_) {
      return _json(503, {'error': 'temporarily_unavailable'});
    }
  }

  /// Holds a row lock during the bounded SMTP call; multiple workers cannot send concurrently.
  /// A crash after SMTP acceptance may resend the same code, never create a new challenge.
  Future<void> deliverOne(SendCode send) => db.runTx((tx) async {
    final rows = await tx.execute(
      '''SELECT m.* FROM mail_outbox m JOIN challenges c USING(challenge_id)
      WHERE NOT m.delivered AND m.attempts<8 AND m.next_at<=CURRENT_TIMESTAMP
      AND NOT c.consumed AND c.expires_at>CURRENT_TIMESTAMP FOR UPDATE OF m SKIP LOCKED LIMIT 1''',
    );
    if (rows.isEmpty) return;
    final row = rows.single.toColumnMap();
    var delivered = false;
    try {
      final plain = await AesGcm.with256bits().decrypt(
        SecretBox.fromConcatenation(
          base64.decode(row['sealed'] as String),
          nonceLength: 12,
          macLength: 16,
        ),
        secretKey: mailKey,
      );
      final j = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      await send(
        j['email'] as String,
        j['purpose'] as String,
        j['code'] as String,
      ).timeout(const Duration(seconds: 20));
      delivered = true;
    } catch (_) {
      /* No recipient, code, credentials or provider body in logs. */
    }
    await tx.execute(
      Sql.named(
        '''UPDATE mail_outbox SET delivered=@d,attempts=attempts+1,next_at=CURRENT_TIMESTAMP+interval '30 seconds',sealed=CASE WHEN @d THEN '' ELSE sealed END WHERE id=@i''',
      ),
      parameters: {'d': delivered, 'i': row['id']},
    );
  });
}
