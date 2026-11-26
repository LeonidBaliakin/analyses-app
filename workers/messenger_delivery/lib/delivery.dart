import 'dart:convert';

import 'package:http/http.dart' as http;

enum DeliveryMode { disabled, dryRun }

DeliveryMode parseMode(String value) => switch (value) {
  'disabled' => DeliveryMode.disabled,
  'dry_run' => DeliveryMode.dryRun,
  _ => throw StateError(
    'Only disabled and dry_run delivery modes are implemented',
  ),
};

class DeliveryJob {
  DeliveryJob.fromJson(Map<String, dynamic> json)
    : notificationId = json['notificationId'] as String,
      attemptId = json['attemptId'] as String,
      channel = json['channel'] as String,
      template = json['template'] as String,
      locale = json['locale'] as String {
    if (json['simulationOnly'] != true ||
        !{'telegram', 'vk', 'max'}.contains(channel) ||
        !{'activity_available', 'processing_ready'}.contains(template) ||
        !{'ru', 'en'}.contains(locale) ||
        !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(notificationId) ||
        !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(attemptId) ||
        json.keys.any(
          (k) => !{
            'notificationId',
            'attemptId',
            'bindingId',
            'channel',
            'template',
            'locale',
            'simulationOnly',
          }.contains(k),
        )) {
      throw FormatException('Unsupported delivery job');
    }
  }
  final String notificationId, attemptId, channel, template, locale;
}

/// A future live adapter must classify ambiguous provider responses as unknown.
/// It must never convert an unverified timeout into an automatic retry.
abstract interface class DeliveryAdapter {
  String get channel;
  Future<void> simulate(DeliveryJob job);
}

String renderTemplate(DeliveryJob job) => switch ((job.template, job.locale)) {
  ('activity_available', 'ru') =>
    'В приложении есть обновление. Откройте приложение.',
  ('activity_available', 'en') =>
    'There is an update in the app. Open the app.',
  ('processing_ready', 'ru') =>
    'Обработка завершена. Откройте приложение для проверки.',
  ('processing_ready', 'en') =>
    'Processing is complete. Open the app to review.',
  _ => throw FormatException('Unsupported template'),
};

/// Only talks to the internal queue. There is no provider HTTP client here.
class DeliveryWorker {
  DeliveryWorker({
    required this.client,
    required this.endpoint,
    required this.key,
    required this.mode,
    required this.adapter,
  }) {
    if (endpoint.scheme != 'http' && endpoint.scheme != 'https') {
      throw StateError('Invalid queue endpoint');
    }
    if (!endpoint.path.endsWith('/') ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment) {
      throw StateError('Invalid queue endpoint');
    }
    if (key.length < 32) throw StateError('Missing worker credential');
  }
  final http.Client client;
  final Uri endpoint;
  final String key;
  final DeliveryMode mode;
  final DeliveryAdapter adapter;
  int claimed = 0, simulated = 0;
  DateTime? lastSuccess;
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await client
        .post(
          endpoint.resolve(path),
          headers: {
            'content-type': 'application/json',
            'x-notifications-worker-key': key,
          },
          body: jsonEncode({'schemaVersion': 1, ...body}),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200 || response.bodyBytes.length > 16384) {
      throw StateError('Queue request failed');
    }
    final value = jsonDecode(response.body) as Map<String, dynamic>;
    if (value['schemaVersion'] != 1) {
      throw FormatException('Unsupported queue schema');
    }
    return value;
  }

  Future<bool> runOnce() async {
    if (mode == DeliveryMode.disabled) return false;
    final result = await _post(
      'internal/channels/${adapter.channel}/claim',
      {},
    );
    lastSuccess = DateTime.now().toUtc();
    if (result['job'] == null) return false;
    final job = DeliveryJob.fromJson(result['job'] as Map<String, dynamic>);
    if (job.channel != adapter.channel) throw FormatException('Wrong channel');
    claimed++;
    await adapter.simulate(job);
    final receipt = {
      'notificationId': job.notificationId,
      'attemptId': job.attemptId,
      'outcome': 'simulated',
      'code': 'dry_run',
    };
    // Repeating this exact acknowledgement is safe, including after lost ACK.
    for (var attempt = 0; ; attempt++) {
      try {
        await _post('internal/channels/${adapter.channel}/result', receipt);
        break;
      } catch (_) {
        if (attempt >= 2) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    simulated++;
    return true;
  }
}
