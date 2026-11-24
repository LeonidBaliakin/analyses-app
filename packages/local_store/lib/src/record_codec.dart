import 'package:medical_domain/medical_domain.dart';

/// Versioned storage DTO. Domain types do not expose JSON or database rows.
Map<String, Object?> encodeRecord(HealthRecord r) => {
  'format': 1,
  'id': r.id,
  'profileId': r.profileId,
  'kind': r.kind.name,
  'source': 'manual',
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
  if (j['format'] != 1) {
    throw const FormatException('Unsupported record format');
  }
  String text(String key) => j[key] as String;
  CalendarDate date(String key) => CalendarDate.parse(text(key));
  SourceValue value() => SourceValue(
    text('raw'),
    ResultValueKind.values.byName(text('valueKind')),
  );
  return switch (RecordKind.values.byName(text('kind'))) {
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
}
