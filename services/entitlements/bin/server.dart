import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:entitlements_service/entitlements_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  String required(String key) {
    final v = env[key];
    if (v == null || v.isEmpty) throw StateError('Missing configuration: $key');
    return v;
  }

  if (args.contains('--health')) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final r = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:8084/health'),
      )).close();
      await r.drain<void>();
      exit(r.statusCode == 200 ? 0 : 1);
    } catch (_) {
      exit(1);
    } finally {
      client.close(force: true);
    }
  }
  if (args.contains('--grant')) {
    final j = jsonDecode(
      await stdin.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    final owner = j.remove('ownerId') as String;
    final client = HttpClient();
    try {
      final r = await client.putUrl(
        Uri.parse(
          'http://127.0.0.1:8084/internal/policies/${Uri.encodeComponent(owner)}',
        ),
      );
      r.headers.set('x-cloud-admin-key', required('CLOUD_ADMIN_KEY'));
      r.headers.contentType = ContentType.json;
      r.write(jsonEncode(j));
      final response = await r.close();
      stdout.writeln(await response.transform(utf8.decoder).join());
      exit(response.statusCode == 200 ? 0 : 1);
    } finally {
      client.close(force: true);
    }
  }
  final db = Pool.withUrl(required('ENTITLEMENTS_DATABASE_URL'));
  final api = EntitlementsService(
    db,
    serviceKey: required('CLOUD_SERVICE_KEY'),
    adminKey: required('CLOUD_ADMIN_KEY'),
  );
  await api.migrate();
  final server = await shelf.serve(
    api.call,
    env['ENTITLEMENTS_BIND'] ?? '127.0.0.1',
    8084,
  );
  stdout.writeln('Entitlements ready');
  Future<void> stop() async {
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
