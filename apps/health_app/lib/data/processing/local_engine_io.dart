import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:document_processing/document_processing.dart';

ProcessingEngine createLocalProcessingEngine() => LocalProcessingEngine(
  const String.fromEnvironment('LOCAL_PROCESSING_CONFIG'),
);

final class LocalProcessingEngine implements ProcessingEngine {
  LocalProcessingEngine(this.configPath);
  final String configPath;
  Process? _process;
  Future<Map<String, dynamic>?> _config() async {
    if (!(Platform.isMacOS || Platform.isLinux) || configPath.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(await File(configPath).readAsString())
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> runtimeId() async {
    final c = await _config();
    if (c == null) return null;
    try {
      final p = await Process.run(c['python'] as String, [
        c['workerScript'] as String,
        '--config',
        configPath,
        '--capabilities',
      ]).timeout(const Duration(seconds: 15));
      final j = jsonDecode((p.stdout as String).trim()) as Map;
      return j['ready'] == true ? j['runtimeId'] as String : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> run(
    ProcessingJob job,
    Uint8List bytes,
    Cancellation token,
    Future<void> Function(ProcessingStatus, Map<String, dynamic>?) progress,
  ) async {
    final c = await _config();
    if (c == null) throw const ProcessingFailure('unavailable');
    job.original.verify(bytes);
    token.check();
    final dir = await Directory.systemTemp.createTemp(
      'analyses-local-processing-',
    );
    Timer? timer;
    try {
      final file = File('${dir.path}/original');
      await file.writeAsBytes(bytes, flush: true);
      final p = await Process.start(c['python'] as String, [
        c['workerScript'] as String,
        '--config',
        configPath,
        '--file',
        file.path,
      ]);
      _process = p;
      p.stdin.writeln(
        jsonEncode({
          'runtimeId': job.runtimeId,
          'mime': job.original.mime,
          'size': job.original.size,
          'sha256': job.original.sha256,
        }),
      );
      await p.stdin.close();
      final stderr = p.stderr.drain<void>();
      timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (token.cancelled) p.kill();
      });
      final timeout = Timer(const Duration(seconds: 210), () {
        p.kill();
      });
      Map<String, dynamic>? result;
      var total = 0;
      try {
        await for (final line
            in p.stdout
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          token.check();
          total += line.length;
          if (total > 4 * 1024 * 1024) {
            throw const ProcessingFailure('output_limit');
          }
          final j = jsonDecode(line) as Map<String, dynamic>;
          if (j['stage'] == 'failed') {
            throw ProcessingFailure(j['error'] as String);
          }
          if (j['stage'] == 'ready') {
            result = Map<String, dynamic>.from(j['draft'] as Map);
          } else if (['ocr', 'extracting'].contains(j['stage'])) {
            await progress(
              ProcessingStatus.values.byName(j['stage'] as String),
              j.containsKey('pages') ? j : null,
            );
          }
        }
        await p.exitCode;
        await stderr;
        token.check();
      } finally {
        timeout.cancel();
      }
      if (result == null) throw const ProcessingFailure('worker_failed');
      return result;
    } finally {
      timer?.cancel();
      final child = _process;
      child?.kill();
      if (child != null) {
        try {
          await child.exitCode.timeout(const Duration(seconds: 3));
        } catch (_) {
          child.kill(ProcessSignal.sigkill);
        }
      }
      _process = null;
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<void> cancel(ProcessingJob job) async {
    _process?.kill();
  }

  @override
  void close() {
    _process?.kill();
  }
}
