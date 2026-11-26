import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudAccessFailure implements Exception {
  const CloudAccessFailure();
}

/// Policy only. Usage is owned and committed by the service that owns the resource.
class CloudPolicy {
  const CloudPolicy({
    required this.ownerId,
    required this.revision,
    required this.syncEnabled,
    required this.storageEnabled,
    required this.processingEnabled,
    required this.recordLimit,
    required this.storageLimitBytes,
    required this.processingMonthlyLimit,
    this.validUntil,
    this.active = true,
  });
  final String ownerId;
  final int revision, recordLimit, storageLimitBytes, processingMonthlyLimit;
  final bool syncEnabled, storageEnabled, processingEnabled, active;
  final DateTime? validUntil;
  bool get canSync => active && syncEnabled;
  bool get canStore => active && storageEnabled;
  bool get canProcess => active && processingEnabled;
  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'ownerId': ownerId,
    'revision': revision,
    'active': active,
    'syncEnabled': syncEnabled,
    'storageEnabled': storageEnabled,
    'processingEnabled': processingEnabled,
    'recordLimit': recordLimit,
    'storageLimitBytes': storageLimitBytes,
    'processingMonthlyLimit': processingMonthlyLimit,
    'validUntil': validUntil?.toUtc().toIso8601String(),
  };
  factory CloudPolicy.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('cloud policy version');
    }
    int limit(String key) {
      final n = j[key];
      if (n is! int || n < 0 || n > 1000000000000) {
        throw const FormatException('cloud limit');
      }
      return n;
    }

    final p = CloudPolicy(
      ownerId: j['ownerId'] as String,
      revision: j['revision'] as int,
      syncEnabled: j['syncEnabled'] as bool,
      storageEnabled: j['storageEnabled'] as bool,
      processingEnabled: j['processingEnabled'] as bool,
      recordLimit: limit('recordLimit'),
      storageLimitBytes: limit('storageLimitBytes'),
      processingMonthlyLimit: limit('processingMonthlyLimit'),
      validUntil: j['validUntil'] == null
          ? null
          : DateTime.parse(j['validUntil'] as String),
      active: j['active'] as bool,
    );
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(p.ownerId) ||
        p.revision < 1 ||
        (p.validUntil != null && !p.validUntil!.isUtc)) {
      throw const FormatException('cloud scope');
    }
    return p;
  }
}

abstract interface class CloudPolicyGateway {
  Future<CloudPolicy> policy(String owner);
}

class HttpCloudPolicyGateway implements CloudPolicyGateway {
  HttpCloudPolicyGateway(this.endpoint, this.serviceKey, {http.Client? client})
    : client = client ?? http.Client();
  final Uri endpoint;
  final String serviceKey;
  final http.Client client;
  @override
  Future<CloudPolicy> policy(String owner) async {
    try {
      final req = http.Request(
        'GET',
        endpoint.resolve('internal/policies/${Uri.encodeComponent(owner)}'),
      )..followRedirects = false;
      req.headers['x-cloud-service-key'] = serviceKey;
      final response = await client
          .send(req)
          .timeout(const Duration(seconds: 10));
      final b = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 10),
      )) {
        if (b.length + chunk.length > 16384) throw const CloudAccessFailure();
        b.addAll(chunk);
      }
      if (response.statusCode != 200) throw const CloudAccessFailure();
      final p = CloudPolicy.fromJson(
        jsonDecode(utf8.decode(b)) as Map<String, dynamic>,
      );
      if (p.ownerId != owner) throw const CloudAccessFailure();
      return p;
    } catch (_) {
      throw const CloudAccessFailure();
    }
  }

  void close() => client.close();
}
