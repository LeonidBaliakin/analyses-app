import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:records_service/records_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main() async {
  final env = Platform.environment;
  String required(String k) =>
      env[k] ?? (throw StateError('Missing configuration: $k'));
  final db = Pool.withUrl(required('RECORDS_DATABASE_URL'));
  final config = jsonDecode(
    await File(required('RECORDS_IDENTITIES_FILE')).readAsString(),
  ) as List;
  final service = RecordsService(db, [
    for (final entry in config)
      TokenIdentity(entry['ownerId'] as String, entry['tokenSha256'] as String),
  ]);
  await service.migrate();
  for (final entry in config) {
    await service.grant(
      entry['ownerId'] as String,
      entry['profileId'] as String,
    );
  }
  final server = await shelf.serve(
    service.call,
    env['RECORDS_BIND'] ?? '127.0.0.1',
    int.parse(env['PORT'] ?? '8082'),
  );
  stdout.writeln('Records synchronization ready on port ${server.port}');
  Future<void> stop() async {
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
