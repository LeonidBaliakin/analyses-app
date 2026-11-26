import 'dart:async';
import 'dart:io';

import 'package:processing_service/processing_service.dart';
import 'package:postgres/postgres.dart';
import 'package:cloud_access/cloud_access.dart';
import 'package:shelf/shelf_io.dart' as shelf;

Future<void> main() async {
  final env = Platform.environment;
  String required(String k) =>
      env[k] ?? (throw StateError('Missing configuration: $k'));
  final url = required('PROCESSING_DATABASE_URL');
  Connection? leader;
  for (var i = 0; i < 30; i++) {
    try {
      leader = await Connection.openFromUrl(url);
      break;
    } catch (_) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  if (leader == null) throw StateError('Processing database unavailable');
  if ((await leader.execute('SELECT pg_try_advisory_lock(5786206)'))
          .single[0] !=
      true) {
    throw StateError('Processing worker already active');
  }
  unawaited(leader.closed.then((_) => exit(1)));
  final pool = Pool.withUrl(url);
  final service = ProcessingService(
    db: pool,
    documents: Uri.parse(required('PROCESSING_DOCUMENTS_ENDPOINT')),
    cloudPolicies: (env['ENTITLEMENTS_ENDPOINT'] ?? '').isEmpty
        ? null
        : HttpCloudPolicyGateway(
            Uri.parse(required('ENTITLEMENTS_ENDPOINT')),
            required('CLOUD_SERVICE_KEY'),
          ),
    worker: PythonJobWorker(
      python: env['PROCESSING_PYTHON'] ?? 'python3',
      script: required('PROCESSING_WORKER'),
      config: required('PROCESSING_CONFIG'),
    ),
  );
  await service.migrate();
  final server = await shelf.serve(
    service.call,
    env['PROCESSING_BIND'] ?? '127.0.0.1',
    int.parse(env['PORT'] ?? '8081'),
  );
  stdout.writeln('Processing service ready on port ${server.port}');
  final timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
    try {
      await service.tick();
    } catch (_) {
      stderr.writeln('Processing job deferred');
    }
  });
  Future<void> stop() async {
    timer.cancel();
    await server.close(force: true);
    await pool.close();
    await leader?.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
}
