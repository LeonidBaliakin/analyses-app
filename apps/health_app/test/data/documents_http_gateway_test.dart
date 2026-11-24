import 'dart:convert';
import 'dart:typed_data';

import 'package:document_domain/document_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/documents/documents_http_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final bytes = Uint8List.fromList(
    utf8.encode('%PDF-1.7\nSynthetic original\n%%EOF'),
  );
  final o = OriginalDocument(
    documentId: 'd',
    originalId: 'o',
    profileId: 'p',
    fileName: 'source.pdf',
    mime: 'application/pdf',
    size: bytes.length,
    sha256: originalSha256(bytes),
    importedAt: DateTime.utc(2026, 11, 24),
    importSource: 'files',
  );
  test('upload follows the public protocol and keeps byte identity; invalid receipt fails', () async {
    final paths = <String>[];
    var corrupt = false;
    final client = MockClient((req) async {
      paths.add(req.url.path);
      expect(req.headers['authorization'], 'Bearer synthetic-token');
      expect(req.followRedirects, isFalse);
      if (req.method == 'GET') {
        return http.Response.bytes(corrupt ? [0] : bytes, 200);
      }
      if (req.method == 'PUT') {
        expect(req.bodyBytes, bytes);
        return http.Response('{"state":"staged"}', 200);
      }
      return http.Response(
        jsonEncode({
          'schemaVersion': 1,
          'state': req.url.path.endsWith('finalize') ? 'ready' : 'reserved',
          'documentId': 'd',
          'originalId': 'o',
          'size': bytes.length,
          'mime': o.mime,
          'fileName': o.fileName,
          'importSource': o.importSource,
          'importedAt': o.importedAt.toIso8601String(),
          'sha256': corrupt ? '0' * 64 : o.sha256,
        }),
        200,
      );
    });
    final gateway = DocumentsHttpGateway(
      endpoint: Uri.parse('http://localhost:18088'),
      token: 'synthetic-token',
      client: client,
    );
    addTearDown(gateway.close);
    await gateway.upload(o, bytes);
    expect(paths, [
      '/v1/profiles/p/uploads',
      '/v1/profiles/p/uploads/o/content',
      '/v1/profiles/p/uploads/o/finalize',
    ]);
    expect(await gateway.download(o), bytes);
    corrupt = true;
    await expectLater(gateway.download(o), throwsA(isA<OriginalFailure>()));
    await expectLater(
      gateway.upload(o, bytes),
      throwsA(isA<OriginalFailure>()),
    );
  });
  test(
    'remote HTTP, embedded credentials and invalid endpoints are rejected',
    () {
      for (final endpoint in [
        'http://remote.test',
        'https://user:pass@example.test',
        'https://example.test/?secret=x',
        'ftp://localhost',
      ]) {
        expect(
          () => DocumentsHttpGateway(
            endpoint: Uri.parse(endpoint),
            token: 'synthetic',
          ),
          throwsA(isA<OriginalFailure>()),
        );
      }
    },
  );
}
