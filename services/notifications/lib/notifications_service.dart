import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

const channels = {'telegram', 'vk', 'max'};
const templates = {'activity_available', 'processing_ready'};
String nonce() => List.generate(
  32,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

class NotificationError implements Exception {
  const NotificationError(this.status, this.code);
  final int status;
  final String code;
}

/// Owns intents, simulation binding scopes, leases, receipts and state events.
/// Channel workers are stateless and access this database only through HTTP.
class NotificationsService {
  NotificationsService(
    this.db, {
    required this.publisherKey,
    required this.adminKey,
    required this.channelKeys,
  });
  final Pool db;
  final String publisherKey, adminKey;
  final Map<String, String> channelKeys;
  bool _key(String? supplied, String expected) {
    final a = sha256.convert(utf8.encode(supplied ?? '')).bytes,
        b = sha256.convert(utf8.encode(expected)).bytes;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return expected.isNotEmpty && diff == 0;
  }

  void _id(Object? value) {
    if (value is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(value)) {
      throw const NotificationError(400, 'invalid_id');
    }
  }

  void _shape(Map<String, dynamic> body, Set<String> keys) {
    if (body.keys.any((k) => !keys.contains(k))) {
      throw const NotificationError(400, 'unexpected_fields');
    }
  }

  Future<void> migrate() => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(5786210)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS notification_schema(id int PRIMARY KEY CHECK(id=1),version int NOT NULL)',
    );
    await tx.execute(
      'INSERT INTO notification_schema VALUES(1,1) ON CONFLICT DO NOTHING',
    );
    if ((await tx.execute('SELECT version FROM notification_schema'))
            .single[0] !=
        1) {
      throw StateError('Unsupported notification schema');
    }
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS bindings(binding_id text PRIMARY KEY,owner_id text NOT NULL,channel text NOT NULL,enabled boolean NOT NULL,simulation_only boolean NOT NULL CHECK(simulation_only))''',
      '''CREATE TABLE IF NOT EXISTS notifications(notification_id text PRIMARY KEY,owner_id text NOT NULL,channel text NOT NULL,binding_id text NOT NULL REFERENCES bindings(binding_id),request text NOT NULL,template text NOT NULL,locale text NOT NULL,state text NOT NULL,attempts int NOT NULL DEFAULT 0,revision int NOT NULL DEFAULT 1,next_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,expires_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP+interval '24 hours',lease_until timestamptz,attempt_id text,code text)''',
      '''CREATE INDEX IF NOT EXISTS channel_queue ON notifications(channel,state,next_at)''',
      '''CREATE TABLE IF NOT EXISTS receipts(attempt_id text PRIMARY KEY,request text NOT NULL,response text NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS notification_outbox(event_id text PRIMARY KEY,payload text NOT NULL,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP)''',
    ]) {
      await tx.execute(sql);
    }
  });
  Map<String, Object?> view(Map<String, dynamic> row) => {
    'schemaVersion': 1,
    'notificationId': row['notification_id'],
    'channel': row['channel'],
    'state': row['state'],
    'attempts': row['attempts'],
    'revision': row['revision'],
    'code': row['code'],
  };
  Future<void> _event(Session tx, Map<String, dynamic> row) async {
    await tx.execute(
      Sql.named(
        'INSERT INTO notification_outbox VALUES(@i,@j,CURRENT_TIMESTAMP)',
      ),
      parameters: {
        'i': '${row['notification_id']}:${row['revision']}',
        'j': jsonEncode({
          'schemaVersion': 1,
          'type': 'NotificationStateChanged',
          ...view(row),
        }),
      },
    );
  }

  Future<Map<String, dynamic>> _state(
    Session tx,
    String id,
    String state, {
    String? code,
    DateTime? next,
  }) async {
    final r = await tx.execute(
      Sql.named(
        'UPDATE notifications SET state=@s,code=@c,revision=revision+1,next_at=COALESCE(@n,next_at) WHERE notification_id=@i RETURNING *',
      ),
      parameters: {'i': id, 's': state, 'c': code, 'n': next},
    );
    final row = r.single.toColumnMap();
    await _event(tx, row);
    return row;
  }

  Future<Map<String, dynamic>> body(Request req) async {
    final bytes = <int>[];
    await for (final chunk in req.read().timeout(const Duration(seconds: 15))) {
      if (bytes.length + chunk.length > 8192) {
        throw const NotificationError(413, 'too_large');
      }
      bytes.addAll(chunk);
    }
    final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (value['schemaVersion'] != 1) {
      throw const NotificationError(400, 'schema');
    }
    return value;
  }

  Response json(int status, Map<String, Object?> value) => Response(
    status,
    body: jsonEncode({'schemaVersion': 1, ...value}),
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  );
  Future<Response> call(Request req) async {
    try {
      if (req.method == 'GET' && req.url.path == 'health') {
        await db.execute('SELECT 1');
        return json(200, {'status': 'ok', 'simulationOnly': true});
      }
      if (req.url.path.startsWith('webhooks/')) {
        return json(503, {'error': 'webhook_not_implemented'});
      }
      final p = req.url.pathSegments;
      if (p.length == 2 &&
          p[0] == 'internal' &&
          p[1] == 'bindings' &&
          req.method == 'POST') {
        if (!_key(req.headers['x-notifications-admin-key'], adminKey)) {
          throw const NotificationError(401, 'unauthorized');
        }
        final j = await body(req);
        _shape(j, {
          'schemaVersion',
          'bindingId',
          'ownerId',
          'channel',
          'enabled',
          'simulationOnly',
        });
        _id(j['bindingId']);
        _id(j['ownerId']);
        if (!channels.contains(j['channel']) ||
            j['enabled'] is! bool ||
            j['simulationOnly'] != true) {
          throw const NotificationError(400, 'simulation_only');
        }
        final result = await db.execute(
          Sql.named(
            '''INSERT INTO bindings VALUES(@i,@o,@c,@e,true) ON CONFLICT(binding_id) DO UPDATE SET enabled=excluded.enabled WHERE bindings.owner_id=excluded.owner_id AND bindings.channel=excluded.channel RETURNING binding_id''',
          ),
          parameters: {
            'i': j['bindingId'],
            'o': j['ownerId'],
            'c': j['channel'],
            'e': j['enabled'],
          },
        );
        if (result.isEmpty) {
          throw const NotificationError(409, 'binding_mismatch');
        }
        return json(200, {'bindingId': j['bindingId'], 'simulationOnly': true});
      }
      if (p.length >= 2 && p[0] == 'internal' && p[1] == 'notifications') {
        if (!_key(req.headers['x-notifications-publisher-key'], publisherKey)) {
          throw const NotificationError(401, 'unauthorized');
        }
        if (req.method == 'GET' && p.length == 3) {
          _id(p[2]);
          final rows = await db.execute(
            Sql.named('SELECT * FROM notifications WHERE notification_id=@i'),
            parameters: {'i': p[2]},
          );
          if (rows.isEmpty) throw const NotificationError(404, 'not_found');
          return json(200, view(rows.single.toColumnMap()));
        }
        if (req.method != 'POST' || p.length != 2) {
          throw const NotificationError(404, 'not_found');
        }
        final j = await body(req);
        _shape(j, {
          'schemaVersion',
          'notificationId',
          'ownerId',
          'channel',
          'bindingId',
          'template',
          'locale',
        });
        for (final k in ['notificationId', 'ownerId', 'bindingId']) {
          _id(j[k]);
        }
        if (!channels.contains(j['channel']) ||
            !templates.contains(j['template']) ||
            !['ru', 'en'].contains(j['locale'])) {
          throw const NotificationError(400, 'schema');
        }
        final request = jsonEncode({
          for (final k in [
            'notificationId',
            'ownerId',
            'channel',
            'bindingId',
            'template',
            'locale',
          ])
            k: j[k],
        });
        final result = await db.runTx((tx) async {
          await tx.execute(
            Sql.named('SELECT pg_advisory_xact_lock(hashtext(@i))'),
            parameters: {'i': j['notificationId']},
          );
          final binding = await tx.execute(
            Sql.named(
              'SELECT * FROM bindings WHERE binding_id=@b AND owner_id=@o AND channel=@c AND enabled AND simulation_only',
            ),
            parameters: {
              'b': j['bindingId'],
              'o': j['ownerId'],
              'c': j['channel'],
            },
          );
          if (binding.isEmpty) {
            throw const NotificationError(403, 'binding_denied');
          }
          final old = await tx.execute(
            Sql.named('SELECT * FROM notifications WHERE notification_id=@i'),
            parameters: {'i': j['notificationId']},
          );
          if (old.isNotEmpty) {
            final row = old.single.toColumnMap();
            if (row['request'] != request) {
              throw const NotificationError(409, 'operation_mismatch');
            }
            return row;
          }
          final row = (await tx.execute(
            Sql.named(
              "INSERT INTO notifications(notification_id,owner_id,channel,binding_id,request,template,locale,state) VALUES(@i,@o,@c,@b,@q,@t,@l,'queued') RETURNING *",
            ),
            parameters: {
              'i': j['notificationId'],
              'o': j['ownerId'],
              'c': j['channel'],
              'b': j['bindingId'],
              'q': request,
              't': j['template'],
              'l': j['locale'],
            },
          )).single.toColumnMap();
          await _event(tx, row);
          return row;
        });
        return json(200, view(result));
      }
      if (p.length != 4 ||
          p[0] != 'internal' ||
          p[1] != 'channels' ||
          !channels.contains(p[2])) {
        throw const NotificationError(404, 'not_found');
      }
      final channel = p[2];
      if (!_key(
        req.headers['x-notifications-worker-key'],
        channelKeys[channel] ?? '',
      )) {
        throw const NotificationError(401, 'unauthorized');
      }
      if (req.method != 'POST') throw const NotificationError(404, 'not_found');
      if (p[3] == 'claim') {
        _shape(await body(req), {'schemaVersion'});
        final job = await db.runTx((tx) async {
          // An expired lease is ambiguous. Never assume the provider did not accept it.
          final expired = await tx.execute(
            Sql.named(
              "SELECT notification_id FROM notifications WHERE channel=@c AND state='leased' AND lease_until<CURRENT_TIMESTAMP FOR UPDATE SKIP LOCKED LIMIT 100",
            ),
            parameters: {'c': channel},
          );
          for (final r in expired) {
            await _state(tx, r[0] as String, 'unknown', code: 'lease_expired');
          }
          final disabled = await tx.execute(
            Sql.named(
              "SELECT n.notification_id FROM notifications n WHERE channel=@c AND state IN ('queued','retry') AND (expires_at<CURRENT_TIMESTAMP OR NOT EXISTS(SELECT 1 FROM bindings b WHERE b.binding_id=n.binding_id AND b.owner_id=n.owner_id AND b.channel=n.channel AND b.enabled)) FOR UPDATE OF n SKIP LOCKED LIMIT 100",
            ),
            parameters: {'c': channel},
          );
          for (final r in disabled) {
            await _state(
              tx,
              r[0] as String,
              'cancelled',
              code: 'expired_or_disabled',
            );
          }
          final rows = await tx.execute(
            Sql.named(
              "SELECT n.* FROM notifications n JOIN bindings b USING(binding_id) WHERE n.channel=@c AND n.state IN ('queued','retry') AND n.next_at<=CURRENT_TIMESTAMP AND n.expires_at>CURRENT_TIMESTAMP AND b.enabled AND b.simulation_only AND b.owner_id=n.owner_id AND b.channel=n.channel ORDER BY n.next_at,n.notification_id FOR UPDATE OF n SKIP LOCKED LIMIT 1",
            ),
            parameters: {'c': channel},
          );
          if (rows.isEmpty) return null;
          final row = rows.single.toColumnMap();
          final updated = (await tx.execute(
            Sql.named(
              "UPDATE notifications SET state='leased',attempts=attempts+1,attempt_id=@a,lease_until=CURRENT_TIMESTAMP+interval '60 seconds',revision=revision+1 WHERE notification_id=@i RETURNING *",
            ),
            parameters: {'a': nonce(), 'i': row['notification_id']},
          )).single.toColumnMap();
          await _event(tx, updated);
          return {
            'notificationId': updated['notification_id'],
            'attemptId': updated['attempt_id'],
            'bindingId': updated['binding_id'],
            'channel': channel,
            'template': updated['template'],
            'locale': updated['locale'],
            'simulationOnly': true,
          };
        });
        return json(200, {'job': job});
      }
      if (p[3] != 'result') throw const NotificationError(404, 'not_found');
      final j = await body(req);
      _shape(j, {
        'schemaVersion',
        'notificationId',
        'attemptId',
        'outcome',
        'code',
        'retryAfterSeconds',
      });
      _id(j['notificationId']);
      _id(j['attemptId']);
      const outcomes = {
        'simulated': {'dry_run'},
        'retry': {'provider_rate_limited', 'transport_not_sent'},
        'unknown': {'ambiguous_result'},
        'failed': {'adapter_unavailable'},
      };
      if (!(outcomes[j['outcome']]?.contains(j['code']) ?? false)) {
        throw const NotificationError(400, 'schema');
      }
      final delay = j['retryAfterSeconds'] ?? 30;
      if (delay is! int || delay < 1 || delay > 86400) {
        throw const NotificationError(400, 'retry_delay');
      }
      final fingerprint = jsonEncode({
        'notificationId': j['notificationId'],
        'attemptId': j['attemptId'],
        'outcome': j['outcome'],
        'code': j['code'],
        'retryAfterSeconds': delay,
      });
      final result = await db.runTx((tx) async {
        final rows = await tx.execute(
          Sql.named(
            'SELECT n.*,b.enabled,CURRENT_TIMESTAMP AS now FROM notifications n JOIN bindings b USING(binding_id) WHERE n.notification_id=@i AND n.channel=@c FOR UPDATE OF n',
          ),
          parameters: {'i': j['notificationId'], 'c': channel},
        );
        if (rows.isEmpty) throw const NotificationError(404, 'not_found');
        final row = rows.single.toColumnMap();
        final old = await tx.execute(
          Sql.named(
            'SELECT request,response FROM receipts WHERE attempt_id=@a',
          ),
          parameters: {'a': j['attemptId']},
        );
        if (old.isNotEmpty) {
          if (old.single[0] != fingerprint) {
            throw const NotificationError(409, 'receipt_mismatch');
          }
          return jsonDecode(old.single[1] as String) as Map<String, dynamic>;
        }
        if (row['attempt_id'] != j['attemptId'] ||
            row['state'] != 'leased' ||
            !(row['lease_until'] as DateTime).isAfter(row['now'] as DateTime)) {
          throw const NotificationError(409, 'stale_lease');
        }
        var state = j['outcome'] as String;
        String code = j['code'] as String;
        if (row['enabled'] != true) {
          state = 'cancelled';
          code = 'binding_disabled';
        }
        if (state == 'retry' && (row['attempts'] as int) >= 5) {
          state = 'failed';
          code = 'retry_exhausted';
        }
        final updated = await _state(
          tx,
          j['notificationId'] as String,
          state,
          code: code,
          next: (row['now'] as DateTime).add(Duration(seconds: delay)),
        );
        final value = view(updated);
        await tx.execute(
          Sql.named('INSERT INTO receipts VALUES(@a,@q,@r)'),
          parameters: {
            'a': j['attemptId'],
            'q': fingerprint,
            'r': jsonEncode(value),
          },
        );
        return value;
      });
      return json(200, result);
    } on NotificationError catch (e) {
      return json(e.status, {'error': e.code});
    } on FormatException {
      return json(400, {'error': 'schema'});
    } on TypeError {
      return json(400, {'error': 'schema'});
    } catch (_) {
      return json(503, {'error': 'unavailable'});
    }
  }
}
