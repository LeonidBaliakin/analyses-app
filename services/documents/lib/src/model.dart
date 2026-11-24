import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const maxBytes = 20 * 1024 * 1024;

final class ApiError implements Exception {
  const ApiError(this.status, this.code);
  final int status;
  final String code;
}

void checkId(String id) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id)) {
    throw const ApiError(400, 'invalid_id');
  }
}

String digest(List<int> bytes) => sha256.convert(bytes).toString();
String detectMime(List<int> bytes) {
  bool starts(List<int> p) =>
      bytes.length >= p.length &&
      Iterable<int>.generate(p.length).every((i) => p[i] == bytes[i]);
  if (starts([37, 80, 68, 70, 45])) return 'application/pdf';
  if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
  if (starts([255, 216, 255])) return 'image/jpeg';
  throw const ApiError(415, 'unsupported_type');
}

Future<Uint8List> readBounded(Stream<List<int>> stream, int limit) async {
  final buffer = BytesBuilder(copy: true);
  await for (final chunk in stream.timeout(const Duration(seconds: 30))) {
    if (buffer.length + chunk.length > limit) {
      throw const ApiError(413, 'too_large');
    }
    buffer.add(chunk);
  }
  return buffer.takeBytes();
}

final class UploadMetadata {
  UploadMetadata(Map<String, dynamic> j)
    : documentId = j['documentId'] as String,
      originalId = j['originalId'] as String,
      fileName = j['fileName'] as String,
      mime = j['mime'] as String,
      size = j['size'] as int,
      sha256 = j['sha256'] as String,
      importSource = j['importSource'] as String,
      importedAt = DateTime.parse(j['importedAt'] as String).toUtc() {
    checkId(documentId);
    checkId(originalId);
    if (fileName.isEmpty ||
        fileName.length > 255 ||
        fileName.contains('\u0000') ||
        !['files', 'camera', 'gallery'].contains(importSource) ||
        size < 1 ||
        size > maxBytes ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) ||
        !['application/pdf', 'image/png', 'image/jpeg'].contains(mime)) {
      throw const ApiError(400, 'invalid_metadata');
    }
  }
  final String documentId, originalId, fileName, mime, sha256;
  final String importSource;
  final DateTime importedAt;
  final int size;
  Map<String, Object> toJson() => {
    'documentId': documentId,
    'originalId': originalId,
    'fileName': fileName,
    'mime': mime,
    'size': size,
    'sha256': sha256,
    'importSource': importSource,
    'importedAt': importedAt.toIso8601String(),
  };
  void verify(List<int> bytes) {
    if (bytes.length != size ||
        digest(bytes) != sha256 ||
        detectMime(bytes) != mime) {
      throw const ApiError(422, 'integrity_mismatch');
    }
  }
}

abstract interface class ObjectStorage {
  Future<Uint8List?> get(String key);
  Future<void> put(String key, Uint8List bytes);
  Future<void> delete(String key);
}
