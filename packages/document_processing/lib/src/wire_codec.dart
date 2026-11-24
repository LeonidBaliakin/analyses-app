import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

import 'draft.dart';

/// Boundary DTO validation. No unsupported field can silently become medical data.
ProcessingDraft decodeGeneratedDraft(
  Map<String, dynamic> j,
  ProcessingJob job,
  TerminologyRelease release,
) {
  if (j['schemaVersion'] != 1 ||
      j['runtimeId'] != job.runtimeId ||
      release.id != job.terminologyReleaseId) {
    throw const ProcessingFailure('schema');
  }
  final versions = Map<String, String>.from(j['versions'] as Map);
  if (![
    'ocr',
    'model',
    'prompt',
    'worker',
  ].every((k) => (versions[k] ?? '').isNotEmpty)) {
    throw const ProcessingFailure('schema');
  }
  final pages = (j['pages'] as List)
      .map((p) => Map<String, dynamic>.from(p as Map))
      .toList();
  if (pages.isEmpty || pages.length > 5) throw const ProcessingFailure('pages');
  final texts = <int, String>{};
  for (final p in pages) {
    final number = p['number'] as int, text = p['text'] as String;
    if (number < 1 ||
        number > 5 ||
        texts.containsKey(number) ||
        text.length > 12000) {
      throw const ProcessingFailure('schema');
    }
    texts[number] = text;
  }
  final input = j['rows'] as List;
  if (input.length > 20) throw const ProcessingFailure('schema');
  final rows = <DraftRow>[];
  for (final (index, value) in input.indexed) {
    final r = Map<String, dynamic>.from(value as Map);
    if (!r.keys.every(
          (k) => [...draftFields, 'page', 'evidence'].contains(k),
        ) ||
        !draftFields.every(r.containsKey)) {
      throw const ProcessingFailure('schema');
    }
    final page = r['page'] as int;
    final text = texts[page];
    if (text == null) throw const ProcessingFailure('schema');
    final evidence = r['evidence'] as String;
    if (evidence.isEmpty ||
        evidence.length > 1000 ||
        !text.contains(evidence)) {
      throw const ProcessingFailure('evidence');
    }
    final source = <String, ExtractedField>{}, review = <String, String>{};
    for (final field in draftFields) {
      final raw = r[field] as String;
      if (raw.length > 500) throw const ProcessingFailure('schema');
      final scope = ['name', 'value', 'unit', 'reference'].contains(field)
          ? evidence
          : text;
      var start = raw.isEmpty ? -1 : scope.indexOf(raw);
      String? issue;
      if (field == 'value' && raw.isNotEmpty) {
        if (classifyValue(raw) != ResultValueKind.qualitative) {
          final name = r['name'] as String;
          final nameStart = evidence.indexOf(name);
          final tail = evidence.substring(
            nameStart < 0 ? 0 : nameStart + name.length,
          );
          final token = RegExp(r'(?:[<>≤≥]=?\s*)?[+-]?\d+(?:[.,]\d+)?')
              .firstMatch(tail)?[0]
              ?.trim();
          // A matching reference token must not conceal a lost comparator in the value.
          if (token != raw.trim()) start = -1;
        } else if (RegExp(r'^[<>≤≥]?=?\s*[+-]?\d').hasMatch(raw.trim())) {
          // Numeric-looking text that includes units/reference needs explicit correction.
          issue = 'mixed_value';
        }
      }
      if (start >= 0 && scope == evidence) start += text.indexOf(evidence);
      // Unbacked LLM text is retained as rejected evidence, never prefilled.
      source[field] = ExtractedField(
        raw,
        page: page,
        start: start < 0 ? null : start,
        issue: issue ?? (raw.isNotEmpty && start < 0 ? 'unbacked' : null),
      );
      review[field] = issue == null && (raw.isEmpty || start >= 0) ? raw : '';
    }
    source['evidence'] = ExtractedField(
      evidence,
      page: page,
      start: text.indexOf(evidence),
    );
    review['date'] = completeDate(review['date']!);
    rows.add(
      normalizeRow(
        DraftRow(
          id: 'row-$index',
          source: source,
          review: review,
          valueKind: classifyValue(review['value']!),
        ),
        release,
      ),
    );
  }
  return ProcessingDraft(
    jobId: job.id,
    originalId: job.original.originalId,
    documentId: job.original.documentId,
    profileId: job.original.profileId,
    originalSha256: job.original.sha256,
    mode: job.mode,
    terminologyReleaseId: release.id,
    versions: versions,
    pages: pages,
    rows: rows,
  );
}

Map<String, Object?> encodeDraft(ProcessingDraft d) => {
  'format': 1,
  'jobId': d.jobId,
  'originalId': d.originalId,
  'documentId': d.documentId,
  'profileId': d.profileId,
  'sha256': d.originalSha256,
  'mode': d.mode.name,
  'terminologyReleaseId': d.terminologyReleaseId,
  'versions': d.versions,
  'pages': d.pages,
  'revision': d.revision,
  'confirmed': d.confirmed,
  'rows': [
    for (final row in d.rows)
      {
        'id': row.id,
        'source': {
          for (final e in row.source.entries)
            e.key: {
              'raw': e.value.raw,
              'page': e.value.page,
              'start': e.value.start,
              'issue': e.value.issue,
            },
        },
        'review': row.review,
        'included': row.included,
        'category': row.category.name,
        'valueKind': row.valueKind.name,
        'candidates': row.candidates,
        'coding': row.coding == null
            ? null
            : {
                'release': row.coding!.terminologyReleaseId,
                'indicator': row.coding!.indicatorId,
                'unit': row.coding!.unitId,
                'sourceName': row.coding!.sourceName,
                'sourceUnit': row.coding!.sourceUnit,
                'sourceLaboratory': row.coding!.sourceLaboratory,
                'sourceSpecimen': row.coding!.sourceSpecimen,
                'sourceMethod': row.coding!.sourceMethod,
              },
      },
  ],
};

ProcessingDraft decodeDraft(Map<String, dynamic> j) {
  if (j['format'] != 1) throw const ProcessingFailure('schema');
  final releaseId = j['terminologyReleaseId'] as String;
  final rows = <DraftRow>[];
  for (final value in j['rows'] as List) {
    final r = Map<String, dynamic>.from(value as Map),
        f = Map<String, String>.from(value['review'] as Map);
    final c = r['coding'] as Map?;
    rows.add(
      DraftRow(
        id: r['id'] as String,
        source: {
          for (final entry in (r['source'] as Map).entries)
            entry.key as String: ExtractedField(
              (entry.value as Map)['raw'] as String,
              page: entry.value['page'] as int?,
              start: entry.value['start'] as int?,
              issue: entry.value['issue'] as String?,
            ),
        },
        review: f,
        included: r['included'] as bool,
        category: AnalysisCategory.values.byName(r['category'] as String),
        valueKind: ResultValueKind.values.byName(r['valueKind'] as String),
        candidates: List<String>.from(r['candidates'] as List),
        coding: c == null
            ? null
            : LabResultCoding(
                terminologyReleaseId: c['release'] as String,
                indicatorId: c['indicator'] as String,
                unitId: c['unit'] as String?,
                sourceName: c['sourceName'] as String,
                sourceUnit: c['sourceUnit'] as String,
                sourceLaboratory: c['sourceLaboratory'] as String,
                sourceSpecimen: c['sourceSpecimen'] as String,
                sourceMethod: c['sourceMethod'] as String,
              ),
      ),
    );
  }
  return ProcessingDraft(
    jobId: j['jobId'] as String,
    originalId: j['originalId'] as String,
    documentId: j['documentId'] as String,
    profileId: j['profileId'] as String,
    originalSha256: j['sha256'] as String,
    mode: ProcessingMode.values.byName(j['mode'] as String),
    terminologyReleaseId: releaseId,
    versions: Map<String, String>.from(j['versions'] as Map),
    pages: (j['pages'] as List)
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList(),
    rows: rows,
    revision: j['revision'] as int,
    confirmed: j['confirmed'] as bool,
  );
}
