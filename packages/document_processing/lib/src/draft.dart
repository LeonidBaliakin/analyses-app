import 'dart:typed_data';

import 'package:document_domain/document_domain.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

enum ProcessingMode { local, ownServer }

enum ProcessingStatus {
  queued,
  ocr,
  extracting,
  ready,
  failed,
  cancelled,
  confirmed,
}

const draftFields = [
  'name',
  'value',
  'unit',
  'reference',
  'date',
  'laboratory',
  'specimen',
  'method',
];

final class ProcessingFailure implements Exception {
  const ProcessingFailure(this.code);
  final String code;
}

final class ProcessingCancelled implements Exception {
  const ProcessingCancelled();
}

final class Cancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw const ProcessingCancelled();
  }
}

final class ExtractedField {
  const ExtractedField(this.raw, {this.page, this.start, this.issue});
  final String raw;
  final int? page, start;
  final String? issue;
}

final class DraftRow {
  DraftRow({
    required this.id,
    required Map<String, ExtractedField> source,
    required Map<String, String> review,
    this.included = true,
    this.category = AnalysisCategory.blood,
    this.valueKind = ResultValueKind.numeric,
    this.coding,
    List<String> candidates = const [],
  }) : source = Map.unmodifiable(source),
       review = Map.unmodifiable(review),
       candidates = List.unmodifiable(candidates);
  final String id;
  final Map<String, ExtractedField> source;
  final Map<String, String> review;
  final bool included;
  final AnalysisCategory category;
  final ResultValueKind valueKind;
  final LabResultCoding? coding;
  final List<String> candidates;
  DraftRow edit(
    Map<String, String> fields, {
    bool? included,
    AnalysisCategory? category,
    ResultValueKind? valueKind,
    LabResultCoding? coding,
  }) => DraftRow(
    id: id,
    source: source,
    review: fields,
    included: included ?? this.included,
    category: category ?? this.category,
    valueKind: valueKind ?? this.valueKind,
    coding: coding,
    candidates: candidates,
  );
}

final class ProcessingDraft {
  ProcessingDraft({
    required this.jobId,
    required this.originalId,
    required this.documentId,
    required this.profileId,
    required this.originalSha256,
    required this.mode,
    required this.terminologyReleaseId,
    required Map<String, String> versions,
    required List<Map<String, dynamic>> pages,
    required List<DraftRow> rows,
    this.revision = 1,
    this.confirmed = false,
  }) : versions = Map.unmodifiable(versions),
       pages = List.unmodifiable(
         pages.map((p) => Map<String, dynamic>.unmodifiable(p)),
       ),
       rows = List.unmodifiable(rows);
  final String jobId,
      originalId,
      documentId,
      profileId,
      originalSha256,
      terminologyReleaseId;
  final ProcessingMode mode;
  final Map<String, String> versions;
  final List<Map<String, dynamic>> pages;
  final List<DraftRow> rows;
  final int revision;
  final bool confirmed;
  ProcessingDraft edited(
    List<DraftRow> rows, {
    int? revision,
    bool? confirmed,
  }) => ProcessingDraft(
    jobId: jobId,
    originalId: originalId,
    documentId: documentId,
    profileId: profileId,
    originalSha256: originalSha256,
    mode: mode,
    terminologyReleaseId: terminologyReleaseId,
    versions: versions,
    pages: pages,
    rows: rows,
    revision: revision ?? this.revision,
    confirmed: confirmed ?? this.confirmed,
  );
}

final class ProcessingJob {
  const ProcessingJob({
    required this.id,
    required this.original,
    required this.mode,
    required this.terminologyReleaseId,
    required this.runtimeId,
    this.status = ProcessingStatus.queued,
    this.error,
    this.updatedAt,
    this.artifact,
  });
  final String id, terminologyReleaseId, runtimeId;
  final OriginalDocument original;
  final ProcessingMode mode;
  final ProcessingStatus status;
  final String? error;
  final DateTime? updatedAt;
  final Map<String, dynamic>? artifact;
}

abstract interface class ProcessingEngine {
  Future<String?> runtimeId();
  Future<Map<String, dynamic>> run(
    ProcessingJob job,
    Uint8List bytes,
    Cancellation cancellation,
    Future<void> Function(ProcessingStatus, Map<String, dynamic>?) progress,
  );
  Future<void> cancel(ProcessingJob job);
  void close();
}

abstract interface class DraftRepository {
  Future<void> createProcessingJob(ProcessingJob job);
  Future<List<ProcessingJob>> processingJobs(
    String profileId,
    String originalId,
  );
  Future<void> setProcessingStatus(
    String profileId,
    String jobId,
    ProcessingStatus status, {
    String? error,
    Map<String, dynamic>? artifact,
  });
  Future<ProcessingDraft> storeGeneratedDraft(ProcessingDraft draft);
  Future<ProcessingDraft?> readDraft(String profileId, String jobId);
  Future<ProcessingDraft> saveDraft(
    ProcessingDraft draft,
    int expectedRevision,
  );
  Future<List<String>> confirmDraft(
    ProcessingDraft draft,
    String operationId,
    int expectedRevision,
  );
}

ResultValueKind classifyValue(String raw) {
  if (raw.trim().isEmpty) return ResultValueKind.missing;
  for (final kind in [ResultValueKind.numeric, ResultValueKind.comparison]) {
    try {
      SourceValue(raw, kind).validate();
      return kind;
    } on InvalidRecord {
      /* qualitative below */
    }
  }
  return ResultValueKind.qualitative;
}

String completeDate(String raw) {
  try {
    return CalendarDate.parse(raw).toString();
  } catch (_) {}
  final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(raw.trim());
  if (m != null) {
    try {
      return CalendarDate(
        int.parse(m[3]!),
        int.parse(m[2]!),
        int.parse(m[1]!),
      ).toString();
    } catch (_) {}
  }
  return '';
}

DraftRow normalizeRow(DraftRow row, TerminologyRelease release) {
  final f = row.review;
  final unit = release.findUnits(f['unit'] ?? '').conceptIds.singleOrNull;
  final matches = release.findIndicators(
    f['name'] ?? '',
    sourceSystem: f['laboratory'] ?? '',
    specimen: f['specimen'] ?? '',
    method: f['method'] ?? '',
    unitId: unit,
  );
  return DraftRow(
    id: row.id,
    source: row.source,
    review: f,
    included: row.included,
    category: row.category,
    valueKind: row.valueKind,
    coding: row.coding,
    candidates: List.unmodifiable(matches.conceptIds),
  );
}

List<LabResult> confirmedResults(ProcessingDraft draft) {
  if (draft.rows.where((r) => r.included).isEmpty) {
    throw const ProcessingFailure('empty');
  }
  final result = <LabResult>[];
  for (final row in draft.rows.where((r) => r.included)) {
    final f = row.review;
    final date = completeDate(f['date'] ?? '');
    if (date.isEmpty) throw const ProcessingFailure('date');
    final record = LabResult(
      id: 'import-${draft.originalId}-${row.id}',
      profileId: draft.profileId,
      name: f['name'] ?? '',
      value: SourceValue(f['value'] ?? '', row.valueKind),
      date: CalendarDate.parse(date),
      category: row.category,
      unit: f['unit'] ?? '',
      reference: f['reference'] ?? '',
      laboratory: f['laboratory'] ?? '',
      method: f['method'] ?? '',
      specimen: f['specimen'] ?? '',
      coding: row.coding,
      documentSource: DocumentRecordSource(
        documentId: draft.documentId,
        originalId: draft.originalId,
        originalSha256: draft.originalSha256,
        jobId: draft.jobId,
        draftRevision: draft.revision,
        rowId: row.id,
        versions: {
          ...draft.versions,
          'terminology': draft.terminologyReleaseId,
        },
        fields: {
          for (final e in row.source.entries)
            e.key: e.value.issue == null ? e.value.raw : '',
        },
      ),
    );
    record.validate();
    result.add(record);
  }
  return result;
}
