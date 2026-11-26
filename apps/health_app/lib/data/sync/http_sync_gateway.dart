import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:record_sync/record_sync.dart';

import '../network/cloud_client.dart';

class HttpSyncGateway implements SyncGateway {
  HttpSyncGateway({
    required this.endpoint,
    required this.token,
    required this.profileId,
    http.Client? client,
  }) : _client = client ?? createCloudClient() {
    if (endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        !['', '/'].contains(endpoint.path) ||
        endpoint.host.isEmpty ||
        (!usesCloudCookies && token.trim().isEmpty) ||
        (endpoint.scheme != 'https' &&
            !(endpoint.scheme == 'http' &&
                [
                  'localhost',
                  '127.0.0.1',
                  '::1',
                  '10.0.2.2',
                ].contains(endpoint.host)))) {
      throw const SyncFailure('connection');
    }
  }
  final Uri endpoint;
  final String token, profileId;
  final http.Client _client;
  String? _owner;
  Future<Map<String, dynamic>> _request(
    String method,
    String action, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    try {
      final uri = endpoint
          .resolve('v1/profiles/$profileId/$action')
          .replace(queryParameters: query);
      final request = http.Request(method, uri)..followRedirects = false;
      request.headers.addAll({
        if (token.isNotEmpty) 'authorization': 'Bearer $token',
        'x-app-request': '1',
        'x-account-owner': ?_owner,
        'content-type': 'application/json',
      });
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        if (bytes.length + chunk.length > 4 * 1024 * 1024) {
          throw const SyncFailure('schema');
        }
        bytes.addAll(chunk);
      }
      if (response.statusCode != 200) {
        String code = 'server';
        try {
          code = (jsonDecode(utf8.decode(bytes)) as Map)['error'] as String;
        } catch (_) {}
        throw SyncFailure(
          response.statusCode == 401
              ? 'unauthorized'
              : response.statusCode == 404
              ? 'access'
              : code,
          retryable: response.statusCode >= 500 || response.statusCode == 429,
        );
      }
      try {
        final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        if (j['schemaVersion'] != 1) throw const SyncFailure('schema');
        return j;
      } catch (_) {
        throw const SyncFailure('schema');
      }
    } on SyncFailure {
      rethrow;
    } catch (_) {
      throw const SyncFailure('network', retryable: true);
    }
  }

  @override
  Future<SyncIdentity> identity() async {
    final j = await _request('GET', 'sync-access');
    if (j['profileId'] != profileId ||
        j['ownerId'] is! String ||
        j['epoch'] is! String ||
        j['canWrite'] is! bool) {
      throw const SyncFailure('schema');
    }
    _owner = j['ownerId'] as String;
    return SyncIdentity(
      j['ownerId'] as String,
      profileId,
      j['epoch'] as String,
      j['canWrite'] as bool,
    );
  }

  @override
  Future<SyncChangePage> pull(int cursor, String epoch) async {
    try {
      final j = await _request(
        'GET',
        'sync-changes',
        query: {'cursor': '$cursor', 'epoch': epoch},
      );
      return SyncChangePage(
        j['epoch'] as String,
        j['cursor'] as int,
        j['more'] as bool,
        [
          for (final r in j['records'] as List)
            RemoteRecord.fromJson(r as Map<String, dynamic>),
        ],
      );
    } on SyncFailure {
      rethrow;
    } catch (_) {
      throw const SyncFailure('schema');
    }
  }

  @override
  Future<SyncReply> push(SyncCommand command, String epoch) async {
    try {
      final j = await _request(
        'POST',
        'sync-operations',
        body: {...command.toJson(), 'epoch': epoch},
      );
      return SyncReply(
        j['applied'] as bool,
        RemoteRecord.fromJson(j['current'] as Map<String, dynamic>),
      );
    } on SyncFailure {
      rethrow;
    } catch (_) {
      throw const SyncFailure('schema');
    }
  }

  @override
  void close() => _client.close();
}
