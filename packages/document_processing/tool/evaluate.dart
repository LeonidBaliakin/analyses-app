// Summarize real OCR/LLM outputs through the shared boundary validator.
import 'dart:convert';
import 'dart:io';

import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:medical_terminology/medical_terminology.dart';

Future<void> main() async {
  final input = jsonDecode(
    await File('../../.runtime/processing/evaluation.json').readAsString(),
  ) as Map<String, dynamic>;
  final results = <Map<String, Object?>>[];
  for (final raw in input['cases'] as List) {
    final c = raw as Map<String, dynamic>,
        expected = (c['expected'] as List).cast<Map<String, dynamic>>();
    final artifact = c['artifact'] as Map<String, dynamic>?;
    final text = artifact == null
        ? ''
        : (artifact['pages'] as List).map((p) => p['text']).join('\n');
    final ocrErrors = <String>[],
        llmErrors = <String>[],
        reviewErrors = <String>[];
    for (final row in expected) {
      for (final f in ['name', 'value', 'unit', 'reference', 'date']) {
        if (row[f] != '' && !text.contains(row[f] as String)) {
          ocrErrors.add('${row['name']}:$f');
        }
      }
    }
    String? error = c['error'] as String?;
    int? rowCount;
    int unbacked = 0;
    Map<String, String>? versions;
    if (c['draft'] != null) {
      final j = c['draft'] as Map<String, dynamic>;
      final o = OriginalDocument(
        documentId: 'quality-doc',
        originalId: 'quality-original',
        profileId: 'quality',
        fileName: 'synthetic',
        mime: c['mime'] as String,
        size: c['size'] as int,
        sha256: c['sha256'] as String,
        importedAt: DateTime.utc(2026, 11, 24),
        importSource: 'files',
      );
      final job = ProcessingJob(
        id: 'quality-job',
        original: o,
        mode: ProcessingMode.values.byName(c['mode'] as String),
        terminologyReleaseId: bundledTerminology.active.id,
        runtimeId: j['runtimeId'] as String,
      );
      try {
        final draft = decodeGeneratedDraft(j, job, bundledTerminology.active);
        rowCount = draft.rows.length;
        versions = draft.versions;
        unbacked = draft.rows
            .expand((r) => r.source.values)
            .where((f) => f.issue != null)
            .length;
        for (final target in expected) {
          final model = (j['rows'] as List)
              .cast<Map<String, dynamic>>()
              .where((r) => r['name'] == target['name'])
              .firstOrNull;
          final row = draft.rows
              .where((r) => r.review['name'] == target['name'])
              .firstOrNull;
          for (final f in ['name', 'value', 'unit', 'reference', 'date']) {
            if (model == null || model[f] != target[f]) {
              llmErrors.add('${target['name']}:$f');
            }
            final expectedReview = f == 'date'
                ? completeDate(target[f] as String)
                : target[f];
            if (row == null || row.review[f] != expectedReview) {
              reviewErrors.add('${target['name']}:$f');
            }
          }
        }
      } catch (_) {
        error = 'shared_validation_failed';
      }
    }
    results.add({
      'fixture': c['fixture'],
      'mode': c['mode'],
      'sha256': c['sha256'],
      'seconds': c['seconds'],
      'expectedRows': expected.length,
      'draftRows': rowCount,
      'ocrFieldErrors': ocrErrors,
      'llmFieldErrors': llmErrors,
      'reviewFieldErrors': reviewErrors,
      'rejectedFields': unbacked,
      'error': error,
      'versions': versions,
    });
  }
  final report = {
    'schemaVersion': 1,
    'date': '2026-11-24',
    'model': 'Qwen2.5-1.5B-Instruct Q4_K_M',
    'localRuntime': input['localRuntime'],
    'serverRuntime': input['serverRuntime'],
    'llamaRssPeakKiB': input['llamaRssPeakKiB'],
    'rssSamplingMs': input['llamaRssSamplingMs'],
    'cases': results,
  };
  await File('../../docs/reports/processing-pilot-2026-11-24.json')
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
  for (final c in results) {
    stdout.writeln(
      '${c['fixture']}/${c['mode']}: OCR errors=${(c['ocrFieldErrors'] as List).length}, LLM errors=${(c['llmFieldErrors'] as List).length}, review errors=${(c['reviewFieldErrors'] as List).length}, error=${c['error']}',
    );
  }
  stdout.writeln(
    'Observed llama-server peak RSS: ${input['llamaRssPeakKiB']} KiB',
  );
}
