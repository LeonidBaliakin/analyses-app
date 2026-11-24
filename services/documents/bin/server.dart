import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:documents_service/documents_service.dart';
import 'package:minio/minio.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  final env = Platform.environment;
  String required(String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing configuration: $key');
    }
    return value;
  }

  final db = Pool.withUrl(required('DOCUMENTS_DATABASE_URL'));
  final s3Uri = Uri.parse(required('DOCUMENTS_S3_ENDPOINT'));
  final s3 = S3Storage(
    Minio(
      endPoint: s3Uri.host,
      port: s3Uri.port,
      useSSL: s3Uri.scheme == 'https',
      accessKey: required('DOCUMENTS_S3_ACCESS_KEY'),
      secretKey: required('DOCUMENTS_S3_SECRET_KEY'),
      region: 'us-east-1',
      pathStyle: true,
    ),
    required('DOCUMENTS_S3_BUCKET'),
  );
  final store = DocumentsStore(db, s3);
  var databaseReady = false;
  for (var attempt = 0; attempt < 30; attempt++) {
    try {
      await store.migrate();
      databaseReady = true;
      break;
    } on StateError {
      rethrow;
    } catch (_) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  if (!databaseReady) throw StateError('Documents database unavailable');
  // Explicit local pilot adapter. No public registration or caller-selected owner.
  final identities = <TokenIdentity>[];
  final config = jsonDecode(
    await File(required('DOCUMENTS_IDENTITIES_FILE')).readAsString(),
  ) as List;
  for (final entry in config) {
    final j = entry as Map<String, dynamic>;
    identities.add(
      TokenIdentity(j['ownerId'] as String, j['tokenSha256'] as String),
    );
    await store.grant(
      j['ownerId'] as String,
      j['profileId'] as String,
      j['quotaBytes'] as int,
    );
  }
  var initialized = false;
  for (var attempt = 0; attempt < 30; attempt++) {
    try {
      await s3.initialize();
      initialized = true;
      break;
    } catch (_) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  if (!initialized) throw StateError('Object storage unavailable');
  final service = DocumentsService(
    store,
    identities: identities,
    allowedOrigins: (env['DOCUMENTS_ALLOWED_ORIGINS'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet(),
  );
  final server = await io.serve(
    service.call,
    env['DOCUMENTS_BIND'] ?? '127.0.0.1',
    int.parse(env['PORT'] ?? '8080'),
  );
  server.autoCompress = false;
  stdout.writeln('Documents ready on port ${server.port}');
  var cleaning = false;
  final timer = Timer.periodic(const Duration(minutes: 1), (_) async {
    if (cleaning) return;
    cleaning = true;
    try {
      await store.cleanup();
    } catch (_) {
      stderr.writeln('Documents cleanup deferred');
    } finally {
      cleaning = false;
    }
  });
  Future<void> shutdown() async {
    timer.cancel();
    await server.close(force: true);
    await db.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(shutdown()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(shutdown()));
}
