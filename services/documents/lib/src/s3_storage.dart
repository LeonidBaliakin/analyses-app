import 'dart:typed_data';

import 'package:minio/minio.dart';

import 'model.dart';

final class S3Storage implements ObjectStorage {
  S3Storage(this.client, this.bucket);
  final Minio client;
  final String bucket;

  Future<void> initialize() async {
    if (!await client.bucketExists(bucket)) await client.makeBucket(bucket);
  }

  @override
  Future<Uint8List?> get(String key) async {
    try {
      final stream = await client
          .getObject(bucket, key)
          .timeout(const Duration(seconds: 30));
      return await readBounded(stream, maxBytes);
    } on MinioS3Error catch (e) {
      if (e.error?.code == 'NoSuchKey' || e.error?.code == 'NotFound') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> put(String key, Uint8List bytes) async {
    await client
        .putObject(bucket, key, Stream.value(bytes), size: bytes.length)
        .timeout(const Duration(seconds: 60));
  }

  @override
  Future<void> delete(String key) =>
      client.removeObject(bucket, key).timeout(const Duration(seconds: 30));
}
