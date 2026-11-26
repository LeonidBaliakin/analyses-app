import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:notifications_service/notifications_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  String required(String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing configuration: $key');
    }
    return value;
  }

  // Local administrative helper: reads JSON on stdin, never prints keys.
  if (args.contains('--health') || args.contains('--request')) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      var path = 'health', method = 'GET';
      String? key, header;
      Object? body;
      if (args.contains('--request')) {
        final input = jsonDecode(
          await stdin.transform(utf8.decoder).join(),
        ) as Map<String, dynamic>;
        switch (input['operation']) {
          case 'binding':
            path = 'internal/bindings';
            method = 'POST';
            header = 'x-notifications-admin-key';
            key = required('NOTIFICATIONS_ADMIN_KEY');
            body = input['body'];
          case 'enqueue':
            path = 'internal/notifications';
            method = 'POST';
            header = 'x-notifications-publisher-key';
            key = required('NOTIFICATIONS_PUBLISHER_KEY');
            body = input['body'];
          case 'status':
            final id = input['notificationId'] as String;
            if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id)) {
              throw FormatException('Invalid id');
            }
            path = 'internal/notifications/$id';
            header = 'x-notifications-publisher-key';
            key = required('NOTIFICATIONS_PUBLISHER_KEY');
          default:
            throw FormatException('Unknown operation');
        }
      }
      final req = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:8085/$path'),
      );
      if (header != null) req.headers.set(header, key!);
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close().timeout(const Duration(seconds: 10));
      final output = await res.transform(utf8.decoder).join();
      if (args.contains('--request')) stdout.writeln(output);
      exitCode = res.statusCode == 200 ? 0 : 1;
    } catch (_) {
      stderr.writeln('Notifications request failed');
      exitCode = 1;
    } finally {
      client.close(force: true);
    }
    return;
  }
  final publisher = required('NOTIFICATIONS_PUBLISHER_KEY'),
      admin = required('NOTIFICATIONS_ADMIN_KEY');
  final keys = {
    for (final c in channels)
      c: required('NOTIFICATIONS_${c.toUpperCase()}_KEY'),
  };
  final all = [publisher, admin, ...keys.values];
  if (all.any((k) => k.length < 32) || all.toSet().length != all.length) {
    throw StateError(
      'Configure distinct notification credentials of at least 32 characters',
    );
  }
  final db = Pool.withUrl(required('NOTIFICATIONS_DATABASE_URL'));
  final api = NotificationsService(
    db,
    publisherKey: publisher,
    adminKey: admin,
    channelKeys: keys,
  );
  await api.migrate();
  final server = await shelf.serve(
    api.call,
    env['NOTIFICATIONS_BIND'] ?? '127.0.0.1',
    8085,
  );
  stdout.writeln('Notifications ready: simulation only');
  Future<void> stop() async {
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
