import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:messenger_delivery/delivery.dart';
import 'package:messenger_delivery/adapters/telegram.dart';
import 'package:messenger_delivery/adapters/vk.dart';
import 'package:messenger_delivery/adapters/max.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--health')) {
    final client = http.Client();
    try {
      final r = await client
          .get(Uri.parse('http://127.0.0.1:8086/health'))
          .timeout(const Duration(seconds: 2));
      exitCode = r.statusCode == 200 ? 0 : 1;
    } catch (_) {
      exitCode = 1;
    } finally {
      client.close();
    }
    return;
  }
  final env = Platform.environment;
  final mode = parseMode(env['DELIVERY_MODE'] ?? 'disabled');
  final adapter = switch (env['DELIVERY_CHANNEL']) {
    'telegram' => TelegramAdapter(),
    'vk' => VkAdapter(),
    'max' => MaxAdapter(),
    _ => throw StateError('Unknown delivery channel'),
  };
  final client = http.Client();
  final worker = DeliveryWorker(
    client: client,
    endpoint: Uri.parse(
      env['NOTIFICATIONS_ENDPOINT'] ?? 'http://notifications:8085/',
    ),
    key: env['NOTIFICATIONS_WORKER_KEY'] ?? '',
    mode: mode,
    adapter: adapter,
  );
  var stopped = false;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8086);
  server.listen((req) async {
    if (req.method != 'GET' || req.uri.path != '/health') {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final ready =
        mode == DeliveryMode.disabled ||
        (worker.lastSuccess != null &&
            DateTime.now().toUtc().difference(worker.lastSuccess!) <
                const Duration(seconds: 30));
    req.response.statusCode = ready ? 200 : 503;
    req.response.headers.contentType = ContentType.json;
    req.response.write(
      jsonEncode({
        'schemaVersion': 1,
        'channel': adapter.channel,
        'mode': mode.name,
        'simulationOnly': true,
        'ready': ready,
        'claimed': worker.claimed,
        'simulated': worker.simulated,
      }),
    );
    await req.response.close();
  });
  Future<void> stop() async {
    stopped = true;
    client.close();
    await server.close(force: true);
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen((_) => unawaited(stop()));
  ProcessSignal.sigint.watch().listen((_) => unawaited(stop()));
  stdout.writeln(
    jsonEncode({
      'event': 'worker_started',
      'channel': adapter.channel,
      'mode': mode.name,
    }),
  );
  while (!stopped) {
    try {
      await worker.runOnce();
    } catch (_) {
      stderr.writeln(
        jsonEncode({'event': 'queue_cycle_failed', 'channel': adapter.channel}),
      );
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}
