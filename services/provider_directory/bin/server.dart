import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:provider_directory_service/provider_directory_service.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  if (args.contains('--health')) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final r = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:8086/health'),
      )).close().timeout(const Duration(seconds: 2));
      await r.drain<void>();
      exitCode = r.statusCode == 200 ? 0 : 1;
    } catch (_) {
      exitCode = 1;
    } finally {
      client.close(force: true);
    }
    return;
  }
  String required(String k) => env[k] ?? (throw StateError('Missing $k'));
  final config = jsonDecode(
    File(env['DIRECTORY_SOURCES'] ?? 'config/sources.json').readAsStringSync(),
  ) as Json;
  final sources = (config['sources'] as List).cast<Json>();
  final keys = {
    for (final s in sources)
      s['id'] as String: required(
        'DIRECTORY_${(s['id'] as String).toUpperCase()}_KEY',
      ),
  };
  final admin = required('DIRECTORY_ADMIN_KEY');
  if ([admin, ...keys.values].any((k) => k.length < 32) ||
      {admin, ...keys.values}.length != keys.length + 1) {
    throw StateError(
      'Configure distinct directory keys of at least 32 characters',
    );
  }
  final db = Pool.withUrl(required('DIRECTORY_DATABASE_URL'));
  final api = DirectoryService(
    db,
    adminKey: admin,
    sourceKeys: keys,
    allowedOrigins: (env['DIRECTORY_ALLOWED_ORIGINS'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList(),
  );
  await api.migrate(
    sources,
    jsonDecode(
      File(env['DIRECTORY_SEED'] ?? 'config/catalog.json').readAsStringSync(),
    ) as Json,
  );
  final server = await shelf.serve(
    api.call,
    env['DIRECTORY_BIND'] ?? '127.0.0.1',
    8086,
  );
  stdout.writeln('Provider directory ready');
  Future<void> stop() async {
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
