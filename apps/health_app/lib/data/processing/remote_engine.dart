import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:document_processing/document_processing.dart';
import 'package:http/http.dart' as http;

import '../network/cloud_client.dart';

final class RemoteProcessingEngine implements ProcessingEngine {
  RemoteProcessingEngine({
    required this.endpoint,
    required this.token,
    required this.profileId,
    this.accountOwnerId,
    http.Client? client,
  }) : _client = client ?? createCloudClient();
  final Uri endpoint;
  final String token, profileId;
  final String? accountOwnerId;
  final http.Client _client;
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final r = http.Request(method, endpoint.resolve(path))
      ..followRedirects = false;
    r.headers.addAll({
      if (token.isNotEmpty) 'authorization': 'Bearer $token',
      'x-app-request': '1',
      'x-account-owner': ?accountOwnerId,
      'content-type': 'application/json',
    });
    if (body != null) r.body = jsonEncode(body);
    final response = await _client.send(r).timeout(const Duration(seconds: 45));
    final b = BytesBuilder();
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      if (b.length + chunk.length > 4 * 1024 * 1024) {
        throw const ProcessingFailure('output_limit');
      }
      b.add(chunk);
    }
    final j = jsonDecode(utf8.decode(b.takeBytes())) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ProcessingFailure(j['error'] as String? ?? 'server');
    }
    return j;
  }

  @override
  Future<String?> runtimeId() async {
    final j = await _request(
      'GET',
      'v1/profiles/$profileId/processing-capabilities',
    );
    // Capability identifies the engine; admission rights/quota are enforced by
    // POST. Existing jobs must still be readable when new admissions are denied.
    return j['runtimeId'] as String?;
  }

  @override
  Future<Map<String, dynamic>> run(
    ProcessingJob job,
    Uint8List bytes,
    Cancellation cancellation,
    Future<void> Function(ProcessingStatus, Map<String, dynamic>?) progress,
  ) async {
    // The server reads the already authorized Documents original, not these local bytes.
    Map<String, dynamic> j;
    try {
      j = await _request(
        'GET',
        'v1/profiles/$profileId/processing-jobs/${job.id}',
      );
    } on ProcessingFailure catch (e) {
      if (e.code != 'not_found') rethrow;
      j = await _request(
        'POST',
        'v1/profiles/$profileId/processing-jobs',
        body: {
          'jobId': job.id,
          'originalId': job.original.originalId,
          'runtimeId': job.runtimeId,
          'terminologyReleaseId': job.terminologyReleaseId,
        },
      );
    }
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (true) {
      cancellation.check();
      if (j['schemaVersion'] != 1 ||
          j['jobId'] != job.id ||
          j['originalId'] != job.original.originalId ||
          j['profileId'] != profileId ||
          j['runtimeId'] != job.runtimeId) {
        throw const ProcessingFailure('schema');
      }
      final status = j['status'] as String;
      if (status == 'ready') {
        return Map<String, dynamic>.from(j['draft'] as Map);
      }
      if (status == 'failed') {
        throw ProcessingFailure(j['error'] as String? ?? 'server');
      }
      if (status == 'cancelled') throw const ProcessingCancelled();
      await progress(
        ProcessingStatus.values.byName(status),
        j['artifact'] == null
            ? null
            : Map<String, dynamic>.from(j['artifact'] as Map),
      );
      if (DateTime.now().isAfter(deadline)) {
        throw const ProcessingFailure('poll_timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      j = await _request(
        'GET',
        'v1/profiles/$profileId/processing-jobs/${job.id}',
      );
    }
  }

  @override
  Future<void> cancel(ProcessingJob job) async {
    await _request(
      'POST',
      'v1/profiles/$profileId/processing-jobs/${job.id}/cancel',
    );
  }

  @override
  void close() => _client.close();
}
