import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:messenger_delivery/delivery.dart';
import 'package:messenger_delivery/adapters/telegram.dart';
import 'package:messenger_delivery/adapters/vk.dart';
import 'package:messenger_delivery/adapters/max.dart';
import 'package:test/test.dart';

void main() {
  const key = 'worker-credential-at-least-32-characters';
  final endpoint = Uri.parse('http://queue.test/');
  Map<String, Object?> job(String channel) => {
    'notificationId': 'event',
    'attemptId': 'attempt',
    'bindingId': 'binding',
    'channel': channel,
    'template': 'processing_ready',
    'locale': 'ru',
    'simulationOnly': true,
  };
  test('default disabled polls nothing; live mode is rejected', () async {
    final client = MockClient((_) async => throw StateError('Must not poll'));
    addTearDown(client.close);
    expect(
      await DeliveryWorker(
        client: client,
        endpoint: endpoint,
        key: key,
        mode: parseMode('disabled'),
        adapter: TelegramAdapter(),
      ).runOnce(),
      false,
    );
    expect(() => parseMode('live'), throwsStateError);
  });
  for (final adapter in <DeliveryAdapter>[
    TelegramAdapter(),
    VkAdapter(),
    MaxAdapter(),
  ]) {
    test(
      '${adapter.channel} simulation uses internal queue only and never reports delivered',
      () async {
        var calls = 0;
        final client = MockClient((req) async {
          expect(req.url.host, 'queue.test');
          expect(req.headers['x-notifications-worker-key'], key);
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['schemaVersion'], 1);
          calls++;
          if (req.url.path.endsWith('/claim')) {
            return http.Response(
              jsonEncode({'schemaVersion': 1, 'job': job(adapter.channel)}),
              200,
            );
          }
          expect(req.url.path, '/internal/channels/${adapter.channel}/result');
          expect(body['outcome'], 'simulated');
          expect(body['code'], 'dry_run');
          expect(body.containsKey('text'), false);
          return http.Response('{"schemaVersion":1,"state":"simulated"}', 200);
        });
        addTearDown(client.close);
        final worker = DeliveryWorker(
          client: client,
          endpoint: endpoint,
          key: key,
          mode: DeliveryMode.dryRun,
          adapter: adapter,
        );
        expect(await worker.runOnce(), true);
        expect(calls, 2);
        expect(worker.simulated, 1);
      },
    );
  }
  test(
    'lost ACK repeats identical receipt without running adapter again',
    () async {
      final adapter = CountingAdapter();
      final receipts = <String>[];
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/claim')) {
          return http.Response(
            jsonEncode({'schemaVersion': 1, 'job': job('telegram')}),
            200,
          );
        }
        receipts.add(req.body);
        if (receipts.length == 1) {
          throw http.ClientException('Synthetic lost ACK');
        }
        return http.Response('{"schemaVersion":1,"state":"simulated"}', 200);
      });
      addTearDown(client.close);
      final worker = DeliveryWorker(
        client: client,
        endpoint: endpoint,
        key: key,
        mode: DeliveryMode.dryRun,
        adapter: adapter,
      );
      await worker.runOnce();
      expect(adapter.calls, 1);
      expect(receipts.length, 2);
      expect(receipts.toSet().length, 1);
    },
  );
  test(
    'foreign channel, live job, medical payload and unknown schema fail closed',
    () async {
      for (final payload in [
        {'schemaVersion': 2, 'job': job('telegram')},
        {'schemaVersion': 1, 'job': job('vk')},
        {
          'schemaVersion': 1,
          'job': {...job('telegram'), 'simulationOnly': false},
        },
        {
          'schemaVersion': 1,
          'job': {...job('telegram'), 'medicalValues': []},
        },
      ]) {
        final adapter = CountingAdapter();
        var count = 0;
        final client = MockClient((_) async {
          count++;
          return http.Response(jsonEncode(payload), 200);
        });
        try {
          final worker = DeliveryWorker(
            client: client,
            endpoint: endpoint,
            key: key,
            mode: DeliveryMode.dryRun,
            adapter: adapter,
          );
          await expectLater(worker.runOnce(), throwsFormatException);
          expect(count, 1);
          expect(adapter.calls, 0);
        } finally {
          client.close();
        }
      }
    },
  );
}

class CountingAdapter implements DeliveryAdapter {
  int calls = 0;
  @override
  String get channel => 'telegram';
  @override
  Future<void> simulate(DeliveryJob job) async {
    calls++;
  }
}
