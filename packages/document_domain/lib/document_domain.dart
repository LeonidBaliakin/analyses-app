import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const maxOriginalBytes = 20 * 1024 * 1024;

enum OriginalCloudState { local, pending, ready }

final class OriginalFailure implements Exception {
  const OriginalFailure(this.code);
  final String code;
}

String originalSha256(List<int> bytes) => sha256.convert(bytes).toString();

String originalMime(List<int> bytes) {
  bool starts(List<int> prefix) =>
      bytes.length >= prefix.length &&
      Iterable<int>.generate(prefix.length).every((i) => bytes[i] == prefix[i]);
  if (starts([0x25, 0x50, 0x44, 0x46, 0x2d])) return 'application/pdf';
  if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
  if (starts([255, 216, 255])) return 'image/jpeg';
  throw const OriginalFailure('unsupported');
}

final class OriginalDocument {
  const OriginalDocument({
    required this.documentId,
    required this.originalId,
    required this.profileId,
    required this.fileName,
    required this.mime,
    required this.size,
    required this.sha256,
    required this.importedAt,
    required this.importSource,
    this.cloudState = OriginalCloudState.local,
    this.cloudDestination,
  });
  final String documentId,
      originalId,
      profileId,
      fileName,
      mime,
      sha256,
      importSource;
  final int size;
  final DateTime importedAt;
  final OriginalCloudState cloudState;
  final String? cloudDestination;

  void validate() {
    final id = RegExp(r'^[A-Za-z0-9_-]{1,100}$');
    if (![documentId, originalId, profileId].every(id.hasMatch) ||
        fileName.isEmpty ||
        fileName.length > 255 ||
        size <= 0 ||
        size > maxOriginalBytes ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) ||
        !['application/pdf', 'image/png', 'image/jpeg'].contains(mime) ||
        !['files', 'camera', 'gallery'].contains(importSource) ||
        !importedAt.isUtc) {
      throw const OriginalFailure('invalid');
    }
  }

  void verify(List<int> bytes) {
    validate();
    if (bytes.length != size ||
        originalSha256(bytes) != sha256 ||
        originalMime(bytes) != mime) {
      throw const OriginalFailure('integrity');
    }
  }
}

abstract interface class OriginalRepository {
  Future<void> importOriginal(OriginalDocument original, Uint8List bytes);
  Future<List<OriginalDocument>> listOriginals(String profileId);
  Future<Uint8List> readOriginal(String profileId, String originalId);
  Future<void> setOriginalCloudState(
    String profileId,
    String originalId,
    OriginalCloudState state, {
    String? destinationId,
  });
}

abstract interface class DocumentsGateway {
  String get destinationId;
  Future<void> upload(OriginalDocument original, Uint8List bytes);
  Future<Uint8List> download(OriginalDocument original);
  void close();
}
