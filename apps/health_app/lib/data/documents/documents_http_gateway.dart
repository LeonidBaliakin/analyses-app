import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:document_domain/document_domain.dart';
import 'package:http/http.dart' as http;

import '../network/cloud_client.dart';

final class DocumentsHttpGateway implements DocumentsGateway {
  DocumentsHttpGateway({
    required this.endpoint,
    required this.token,
    this.accountOwnerId,
    http.Client? client,
  }) : _client = client ?? createCloudClient() {
    if (endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        (endpoint.path.isNotEmpty && endpoint.path != '/') ||
        endpoint.host.isEmpty ||
        (endpoint.scheme != 'https' &&
            !(endpoint.scheme == 'http' &&
                [
                  'localhost',
                  '127.0.0.1',
                  '10.0.2.2',
                  '::1',
                ].contains(endpoint.host))) ||
        (!usesCloudCookies && token.trim().isEmpty)) {
      throw const OriginalFailure('connection');
    }
  }
  final Uri endpoint;
  final String token;
  final String? accountOwnerId;
  final http.Client _client;
  // Conservative scope: a different endpoint or credential needs reconfirmation.
  // Persist only this opaque hash, never the token itself.
  @override
  String get destinationId => originalSha256(
    utf8.encode('${endpoint.toString()}\n${accountOwnerId ?? token}'),
  );

  Future<Uint8List> _request(
    String method,
    String path, {
    List<int>? body,
    String type = 'application/json',
    int limit = 16384,
  }) async {
    final request = http.Request(method, endpoint.resolve(path))
      ..followRedirects = false;
    request.headers.addAll({
      if (token.isNotEmpty) 'authorization': 'Bearer $token',
      'x-app-request': '1',
      'x-account-owner': ?accountOwnerId,
      'content-type': type,
    });
    if (body != null) request.bodyBytes = body;
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    final bytes = BytesBuilder();
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      if (bytes.length + chunk.length > limit) {
        throw const OriginalFailure('integrity');
      }
      bytes.add(chunk);
    }
    final data = bytes.takeBytes();
    if (response.statusCode != 200) {
      String code = 'cloud';
      try {
        code =
            (jsonDecode(utf8.decode(data)) as Map<String, dynamic>)['error']
                as String;
      } catch (_) {}
      throw OriginalFailure(switch (code) {
        'quota_exceeded' => 'quota',
        'unauthorized' => 'unauthorized',
        'not_found' => 'access',
        'cloud_disabled' => 'access',
        'storage_denied' => 'access',
        'cloud_access_unavailable' => 'cloud_access_unavailable',
        'integrity_mismatch' => 'integrity',
        _ => 'cloud',
      });
    }
    return data;
  }

  void _receipt(OriginalDocument o, Uint8List bytes, {bool ready = false}) {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (j['schemaVersion'] != 1 ||
        j['documentId'] != o.documentId ||
        j['originalId'] != o.originalId ||
        j['sha256'] != o.sha256 ||
        j['size'] != o.size ||
        j['mime'] != o.mime ||
        j['fileName'] != o.fileName ||
        j['importSource'] != o.importSource ||
        j['importedAt'] != o.importedAt.toIso8601String() ||
        !(ready ? ['ready'] : ['reserved', 'staged', 'ready']).contains(
          j['state'],
        )) {
      throw const OriginalFailure('integrity');
    }
  }

  @override
  Future<void> upload(OriginalDocument o, Uint8List bytes) async {
    o.verify(bytes);
    final path = 'v1/profiles/${o.profileId}/uploads';
    final receipt = await _request(
      'POST',
      path,
      body: utf8.encode(
        jsonEncode({
          'documentId': o.documentId,
          'originalId': o.originalId,
          'fileName': o.fileName,
          'mime': o.mime,
          'size': o.size,
          'sha256': o.sha256,
          'importSource': o.importSource,
          'importedAt': o.importedAt.toIso8601String(),
        }),
      ),
    );
    _receipt(o, receipt);
    if ((jsonDecode(utf8.decode(receipt)) as Map)['state'] == 'ready') return;
    await _request(
      'PUT',
      '$path/${o.originalId}/content',
      body: bytes,
      type: o.mime,
    );
    _receipt(
      o,
      await _request('POST', '$path/${o.originalId}/finalize'),
      ready: true,
    );
  }

  @override
  Future<Uint8List> download(OriginalDocument o) async {
    final bytes = await _request(
      'GET',
      'v1/profiles/${o.profileId}/originals/${o.originalId}/content',
      limit: maxOriginalBytes,
    );
    o.verify(bytes);
    return bytes;
  }

  @override
  void close() => _client.close();
}
