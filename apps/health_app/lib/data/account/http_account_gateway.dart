import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/account/account_models.dart';
import '../network/cloud_client.dart';

class HttpAccountGateway implements AccountGateway {
  HttpAccountGateway(this.endpoint, {this.token = '', http.Client? client})
    : _client = client ?? createCloudClient() {
    if (endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        !['', '/'].contains(endpoint.path) ||
        (endpoint.scheme != 'https' &&
            !(endpoint.scheme == 'http' &&
                [
                  'localhost',
                  '127.0.0.1',
                  '::1',
                  '10.0.2.2',
                ].contains(endpoint.host)))) {
      throw const AccountFailure('connection');
    }
  }
  final Uri endpoint;
  final http.Client _client;
  String token;
  String? _ownerId;
  Future<Map<String, dynamic>> _request(
    String method,
    String action, [
    Map<String, Object?>? body,
  ]) async {
    try {
      final request = http.Request(
        method,
        endpoint.resolve(action.startsWith('v1/') ? action : 'v1/auth/$action'),
      )..followRedirects = false;
      request.headers.addAll({
        'content-type': 'application/json',
        'x-app-request': '1',
        if (token.isNotEmpty) 'authorization': 'Bearer $token',
        'x-account-owner': ?_ownerId,
      });
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        if (bytes.length + chunk.length > 262144) {
          throw const AccountFailure('schema');
        }
        bytes.addAll(chunk);
      }
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw AccountFailure(j['error'] as String? ?? 'server');
      }
      if (j['schemaVersion'] != 1) throw const AccountFailure('schema');
      return j;
    } on AccountFailure {
      rethrow;
    } catch (_) {
      throw const AccountFailure('network');
    }
  }

  AccountSession _session(Map<String, dynamic> j) {
    try {
      if (j['profileId'] != 'local-profile') {
        throw const AccountFailure('schema');
      }
      token = j['token'] as String? ?? token;
      _ownerId = j['ownerId'] as String;
      return AccountSession(
        ownerId: j['ownerId'] as String,
        email: j['email'] as String,
        sessionId: j['sessionId'] as String,
        token: token,
      );
    } catch (_) {
      throw const AccountFailure('schema');
    }
  }

  Map<String, Object?> _device(String label) => {
    'deviceLabel': label,
    'transport': usesCloudCookies ? 'cookie' : 'bearer',
  };
  @override
  Future<AccountCloudStatus> cloudStatus() async {
    final values = await Future.wait([
      _request('GET', 'v1/profiles/local-profile/cloud-access'),
      _request('GET', 'v1/profiles/local-profile/sync-access'),
      _request('GET', 'v1/profiles/local-profile/processing-capabilities'),
    ]);
    try {
      for (final j in values) {
        if (j['ownerId'] != _ownerId || j['profileId'] != 'local-profile') {
          throw const AccountFailure('schema');
        }
      }
      final policy = values[0]['policy'] as Map,
          storage = values[0]['storage'] as Map,
          quota = values[2]['quota'] as Map;
      int n(Object? v) {
        if (v is! int || v < 0) throw const AccountFailure('schema');
        return v;
      }

      return AccountCloudStatus(
        syncAllowed: values[1]['canWrite'] as bool,
        storageAllowed: values[0]['storageAllowed'] as bool,
        processingAllowed: values[2]['processingAllowed'] as bool,
        recordsUsed: n(values[1]['recordUsage']),
        recordLimit: n(values[1]['recordLimit']),
        bytesUsed: n(storage['usedBytes']),
        bytesReserved: n(storage['reservedBytes']),
        storageLimit: n(storage['limitBytes']),
        jobsUsed: n(quota['usedJobs']),
        jobsReserved: n(quota['reservedJobs']),
        jobLimit: n(quota['limitJobs']),
        period: quota['period'] as String,
        validUntil: policy['validUntil'] == null
            ? null
            : DateTime.parse(policy['validUntil'] as String),
      );
    } catch (_) {
      throw const AccountFailure('cloud_unavailable');
    }
  }

  @override
  Future<String> challenge(String email, bool recovery) async =>
      (await _request('POST', 'challenges', {
            'email': email,
            'purpose': recovery ? 'recover' : 'register',
          }))['challengeId']
          as String;
  @override
  Future<AccountSession> register(
    String challengeId,
    String code,
    String password,
    String label,
  ) async => _session(
    await _request('POST', 'register', {
      'challengeId': challengeId,
      'code': code,
      'password': password,
      ..._device(label),
    }),
  );
  @override
  Future<AccountSession> login(
    String email,
    String password,
    String label,
  ) async => _session(
    await _request('POST', 'login', {
      'email': email,
      'password': password,
      ..._device(label),
    }),
  );
  @override
  Future<void> recover(String challengeId, String code, String password) async {
    await _request('POST', 'recover', {
      'challengeId': challengeId,
      'code': code,
      'password': password,
    });
    token = '';
  }

  @override
  Future<AccountSession> current() async =>
      _session(await _request('GET', 'session'));
  @override
  Future<List<AccountDevice>> devices() async => [
    for (final j in (await _request('GET', 'sessions'))['sessions'] as List)
      AccountDevice(
        j['sessionId'] as String,
        j['deviceLabel'] as String,
        DateTime.parse(j['createdAt'] as String),
        j['current'] as bool,
      ),
  ];
  @override
  Future<void> revoke(String id) async {
    await _request('POST', 'sessions/${Uri.encodeComponent(id)}/revoke', {});
  }

  @override
  Future<void> logout({bool all = false}) async {
    await _request('POST', all ? 'logout-all' : 'logout', {});
    token = '';
  }

  @override
  void close() => _client.close();
}
