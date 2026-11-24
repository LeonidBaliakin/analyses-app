import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:http/http.dart' as http;

import 'model.dart';
import 'store.dart';

/// Local pilot authentication adapter. Production Identity is a separate seam.
final class TokenIdentity {
  const TokenIdentity(this.ownerId, this.tokenSha256);
  final String ownerId, tokenSha256;
}

final class DocumentsService {
  DocumentsService(
    this.store, {
    required this.identities,
    this.allowedOrigins = const {},
    this.processingEndpoint,
    this.recordsEndpoint,
  });
  final DocumentsStore store;
  final List<TokenIdentity> identities;
  final Set<String> allowedOrigins;
  final Uri? processingEndpoint;
  final Uri? recordsEndpoint;
  final http.Client _processingClient = http.Client();

  Future<Response> _processing(Request req, {Uri? endpoint}) async {
    final request = http.Request(
      req.method,
      (endpoint ?? processingEndpoint!).resolveUri(req.url),
    )..followRedirects = false;
    request.headers.addAll({
      'authorization': req.headers['authorization'] ?? '',
      'content-type': 'application/json',
    });
    if (req.method == 'POST') {
      request.bodyBytes = await readBounded(
        req.read(),
        endpoint == null ? 8192 : 262144,
      );
    }
    final response = await _processingClient
        .send(request)
        .timeout(const Duration(seconds: 45));
    final bytes = await readBounded(response.stream, 4 * 1024 * 1024);
    return Response(
      response.statusCode,
      body: bytes,
      headers: {
        'content-type': 'application/json',
        'cache-control': 'no-store',
      },
    );
  }

  Response json(int status, Map<String, Object?> data) => Response(
    status,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json', 'cache-control': 'no-store'},
  );
  String _owner(Request req) {
    final authorization = req.headers['authorization'] ?? '';
    if (!authorization.startsWith('Bearer ') || authorization.length > 2048) {
      throw const ApiError(401, 'unauthorized');
    }
    final hash = sha256
        .convert(utf8.encode(authorization.substring(7)))
        .toString();
    for (final identity in identities) {
      var diff = hash.length ^ identity.tokenSha256.length;
      for (var i = 0; i < hash.length && i < identity.tokenSha256.length; i++) {
        diff |= hash.codeUnitAt(i) ^ identity.tokenSha256.codeUnitAt(i);
      }
      if (diff == 0) return identity.ownerId;
    }
    throw const ApiError(401, 'unauthorized');
  }

  Future<Response> call(Request req) async {
    final supplied = req.headers['x-request-id'] ?? '';
    final requestId = RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(supplied)
        ? supplied
        : List.generate(
            4,
            (_) => Random.secure()
                .nextInt(0x100000000)
                .toRadixString(16)
                .padLeft(8, '0'),
          ).join();
    final origin = req.headers['origin'];
    if (origin != null && !allowedOrigins.contains(origin)) {
      return json(403, {
        'error': 'origin_denied',
      }).change(headers: {'x-request-id': requestId});
    }
    Response response;
    try {
      if (req.method == 'OPTIONS') {
        response = Response(
          204,
          headers: {
            'access-control-allow-methods': 'POST,PUT,GET,HEAD,OPTIONS',
            'access-control-allow-headers':
                'Authorization,Content-Type,Range,X-Request-ID',
            'access-control-max-age': '300',
          },
        );
      } else if (req.url.path == 'health' && req.method == 'GET') {
        response = json(200, {'status': 'ok'});
      } else {
        final owner = _owner(req);
        final p = req.url.pathSegments;
        if (p.length < 4 || p[0] != 'v1' || p[1] != 'profiles') {
          throw const ApiError(404, 'not_found');
        }
        final profile = p[2];
        checkId(profile);
        if (p.length == 4 &&
            ['sync-access', 'sync-changes', 'sync-operations'].contains(p[3]) &&
            recordsEndpoint != null) {
          final access = await store.processingAccess(owner, profile);
          if (p[3] == 'sync-operations' &&
              access['processingAllowed'] != true) {
            throw const ApiError(403, 'cloud_disabled');
          }
          response = await _processing(req, endpoint: recordsEndpoint);
          if (p[3] == 'sync-access' &&
              response.statusCode == 200 &&
              access['processingAllowed'] != true) {
            final capability = jsonDecode(
              await response.readAsString(),
            ) as Map<String, dynamic>;
            response = json(200, {...capability, 'canWrite': false});
          }
        } else if (p.length == 4 &&
            p[3] == 'processing-access' &&
            req.method == 'GET') {
          response = json(200, await store.processingAccess(owner, profile));
        } else if (p.length == 5 &&
            p[3] == 'originals' &&
            req.method == 'GET') {
          checkId(p[4]);
          response = json(200, await store.describe(owner, profile, p[4]));
        } else if (p.length >= 4 &&
            ['processing-jobs', 'processing-capabilities'].contains(p[3]) &&
            processingEndpoint != null) {
          await store.processingAccess(owner, profile);
          response = await _processing(req);
        } else if (p.length == 4 && p[3] == 'uploads' && req.method == 'POST') {
          final bytes = await readBounded(req.read(), 8192);
          final m = UploadMetadata(
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
          );
          response = json(200, await store.reserve(owner, profile, m));
        } else if (p.length == 6 && p[3] == 'uploads') {
          final original = p[4];
          checkId(original);
          if (p[5] == 'content' && req.method == 'PUT') {
            // Authenticate/profile-check before accepting a potentially large body.
            await store.db.run((tx) async {
              final rows = await tx.execute(
                Sql.named(
                  'SELECT 1 FROM profile_access WHERE owner_id=@o AND profile_id=@p AND cloud_enabled',
                ),
                parameters: {'o': owner, 'p': profile},
              );
              if (rows.isEmpty) throw const ApiError(404, 'not_found');
            });
            final bytes = await readBounded(req.read(), maxBytes);
            await store.stage(owner, profile, original, bytes);
            response = json(200, {'state': 'staged'});
          } else if (p[5] == 'finalize' && req.method == 'POST') {
            response = json(
              200,
              await store.finalize(owner, profile, original),
            );
          } else {
            throw const ApiError(404, 'not_found');
          }
        } else if (p.length == 6 &&
            p[3] == 'originals' &&
            p[5] == 'content' &&
            ['GET', 'HEAD'].contains(req.method)) {
          checkId(p[4]);
          final (m, bytes) = await store.download(owner, profile, p[4]);
          response = _download(req, m, bytes);
        } else {
          throw const ApiError(404, 'not_found');
        }
      }
    } on ApiError catch (e) {
      response = json(e.status, {'error': e.code});
    } on FormatException {
      response = json(400, {'error': 'invalid_request'});
    } on TypeError {
      response = json(400, {'error': 'invalid_request'});
    } catch (_) {
      response = json(503, {'error': 'temporarily_unavailable'});
    }
    return response.change(
      headers: {
        'x-content-type-options': 'nosniff',
        'x-request-id': requestId,
        'access-control-allow-origin': ?origin,
        if (origin != null) 'vary': 'Origin',
        'access-control-expose-headers':
            'Content-Range,Content-Length,X-Content-SHA256,X-Request-ID',
      },
    );
  }

  Response _download(Request req, UploadMetadata m, Uint8List bytes) {
    final headers = {
      'content-type': m.mime,
      'cache-control': 'no-store',
      'accept-ranges': 'bytes',
      'x-content-sha256': m.sha256,
      'content-disposition':
          "attachment; filename*=UTF-8''${Uri.encodeComponent(m.fileName)}",
    };
    var start = 0, end = bytes.length - 1, status = 200;
    final range = req.headers['range'];
    if (range != null) {
      final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range);
      if (match == null || (match[1]!.isEmpty && match[2]!.isEmpty)) {
        return Response(
          416,
          headers: {...headers, 'content-range': 'bytes */${bytes.length}'},
        );
      }
      if (match[1]!.isEmpty) {
        final suffix = int.tryParse(match[2]!) ?? 0;
        start = bytes.length - suffix;
        if (start < 0) start = 0;
      } else {
        start = int.tryParse(match[1]!) ?? bytes.length;
        if (match[2]!.isNotEmpty) end = int.tryParse(match[2]!) ?? -1;
      }
      if (end >= bytes.length) end = bytes.length - 1;
      if (start < 0 || start > end || start >= bytes.length) {
        return Response(
          416,
          headers: {...headers, 'content-range': 'bytes */${bytes.length}'},
        );
      }
      status = 206;
      headers['content-range'] = 'bytes $start-$end/${bytes.length}';
    }
    headers['content-length'] = '${end - start + 1}';
    return Response(
      status,
      headers: headers,
      body: req.method == 'HEAD'
          ? null
          : Uint8List.sublistView(bytes, start, end + 1),
    );
  }
}
