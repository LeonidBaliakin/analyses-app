import 'package:medical_domain/medical_domain.dart';

/// Versioned storage DTO. Domain types do not expose JSON or database rows.
Map<String, Object?> encodeRecord(HealthRecord r) => {
  // Keep legacy commands byte-for-byte stable for outbox idempotency.
  'format': r is LabResult && r.documentSource != null
      ? 3
      : r is LabResult && r.coding != null
      ? 2
      : 1,
  'id': r.id,
  'profileId': r.profileId,
  'kind': r.kind.name,
  'source': r is LabResult && r.documentSource != null ? 'document' : 'manual',
  ...switch (r) {
    MedicalProfile() => {
      'name': r.name,
      'birthDate': r.birthDate?.toString(),
      'history': r.history,
      'allergies': r.allergies,
      'notes': r.notes,
    },
    LabResult() => {
      'name': r.name,
      'raw': r.value.raw,
      'valueKind': r.value.kind.name,
      'date': r.date.toString(),
      'category': r.category.name,
      'unit': r.unit,
      'reference': r.reference,
      'laboratory': r.laboratory,
      'method': r.method,
      'specimen': r.specimen,
      'notes': r.notes,
      if (r.coding case final c?) 'coding': _encodeCoding(c),
      if (r.documentSource case final s?)
        'documentSource': {
          'documentId': s.documentId,
          'originalId': s.originalId,
          'sha256': s.originalSha256,
          'jobId': s.jobId,
          'draftRevision': s.draftRevision,
          'rowId': s.rowId,
          'fields': s.fields,
          'versions': s.versions,
        },
    },
    MedicationCourse() => {
      'name': r.name,
      'start': r.start.toString(),
      'end': r.end?.toString(),
      'dosage': r.dosage,
      'schedule': r.schedule,
      'prescribedBy': r.prescribedBy,
      'notes': r.notes,
    },
    HomeMeasurement() => {
      'name': r.name,
      'raw': r.value.raw,
      'valueKind': r.value.kind.name,
      'date': r.date.toString(),
      'unit': r.unit,
      'sourceLabel': r.source,
      'minuteOfDay': r.minuteOfDay,
      'utcOffsetMinutes': r.utcOffsetMinutes,
      'notes': r.notes,
    },
  },
};

HealthRecord decodeRecord(Map<String, dynamic> j) {
  if (![1, 2, 3].contains(j['format']) ||
      (j['format'] != 1 && j['kind'] != 'result')) {
    throw const FormatException('Unsupported record format');
  }
  String text(String key) => j[key] as String;
  CalendarDate date(String key) => CalendarDate.parse(text(key));
  SourceValue value() => SourceValue(
    text('raw'),
    ResultValueKind.values.byName(text('valueKind')),
  );
  final record = switch (RecordKind.values.byName(text('kind'))) {
    RecordKind.profile => MedicalProfile(
      id: text('id'),
      name: text('name'),
      birthDate: j['birthDate'] == null ? null : date('birthDate'),
      history: text('history'),
      allergies: text('allergies'),
      notes: text('notes'),
    ),
    RecordKind.result => LabResult(
      id: text('id'),
      profileId: text('profileId'),
      name: text('name'),
      value: value(),
      date: date('date'),
      category: AnalysisCategory.values.byName(text('category')),
      coding: j['coding'] != null && j['format'] != 1
          ? _decodeCoding(j['coding'] as Map<String, dynamic>)
          : null,
      documentSource: j['format'] == 3
          ? _decodeDocumentSource(j['documentSource'] as Map<String, dynamic>)
          : null,
      unit: text('unit'),
      reference: text('reference'),
      laboratory: text('laboratory'),
      method: text('method'),
      specimen: text('specimen'),
      notes: text('notes'),
    ),
    RecordKind.medication => MedicationCourse(
      id: text('id'),
      profileId: text('profileId'),
      name: text('name'),
      start: date('start'),
      end: j['end'] == null ? null : date('end'),
      dosage: text('dosage'),
      schedule: text('schedule'),
      prescribedBy: text('prescribedBy'),
      notes: text('notes'),
    ),
    RecordKind.measurement => HomeMeasurement(
      id: text('id'),
      profileId: text('profileId'),
      name: text('name'),
      value: value(),
      date: date('date'),
      unit: text('unit'),
      source: text('sourceLabel'),
      minuteOfDay: j['minuteOfDay'] as int?,
      utcOffsetMinutes: j['utcOffsetMinutes'] as int?,
      notes: text('notes'),
    ),
  };
  if (j['format'] != 1) record.validate();
  return record;
}

DocumentRecordSource _decodeDocumentSource(Map<String, dynamic> j) =>
    DocumentRecordSource(
      documentId: j['documentId'] as String,
      originalId: j['originalId'] as String,
      originalSha256: j['sha256'] as String,
      jobId: j['jobId'] as String,
      draftRevision: j['draftRevision'] as int,
      rowId: j['rowId'] as String,
      fields: Map<String, String>.from(j['fields'] as Map),
      versions: Map<String, String>.from(j['versions'] as Map),
    );

Map<String, Object?> _encodeCoding(LabResultCoding c) => {
  'terminologyReleaseId': c.terminologyReleaseId,
  'indicatorId': c.indicatorId,
  'unitId': c.unitId,
  'sourceName': c.sourceName,
  'sourceUnit': c.sourceUnit,
  'sourceLaboratory': c.sourceLaboratory,
  'sourceSpecimen': c.sourceSpecimen,
  'sourceMethod': c.sourceMethod,
  'scope': c.scope,
  'relation': c.relation,
  'matchMethod': c.matchMethod,
  'verification': c.verification,
};

LabResultCoding _decodeCoding(Map<String, dynamic> j) {
  if (j['scope'] != 'record' ||
      j['relation'] != 'exact' ||
      j['matchMethod'] != 'userSelection' ||
      j['verification'] != 'userConfirmed') {
    throw const FormatException('Unsupported coding provenance');
  }
  return LabResultCoding(
    terminologyReleaseId: j['terminologyReleaseId'] as String,
    indicatorId: j['indicatorId'] as String,
    unitId: j['unitId'] as String?,
    sourceName: j['sourceName'] as String,
    sourceUnit: j['sourceUnit'] as String,
    sourceLaboratory: j['sourceLaboratory'] as String,
    sourceSpecimen: j['sourceSpecimen'] as String,
    sourceMethod: j['sourceMethod'] as String,
  );
}
