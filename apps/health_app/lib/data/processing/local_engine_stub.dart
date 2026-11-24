import 'package:document_processing/document_processing.dart';

import 'dart:typed_data';

ProcessingEngine createLocalProcessingEngine() => _Unavailable();

class _Unavailable implements ProcessingEngine {
  @override
  Future<String?> runtimeId() async => null;
  @override
  Future<Map<String, dynamic>> run(
    ProcessingJob job,
    Uint8List bytes,
    Cancellation token,
    Future<void> Function(ProcessingStatus, Map<String, dynamic>?) progress,
  ) async => throw const ProcessingFailure('unavailable');
  @override
  Future<void> cancel(ProcessingJob job) async {}
  @override
  void close() {}
}
