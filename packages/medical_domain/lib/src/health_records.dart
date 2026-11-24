import 'calendar_date.dart';

/// Stable user-selected display groups, not normalized medical concepts.
enum AnalysisCategory {
  carbohydrate,
  blood,
  lipid,
  vitamin,
  iron,
  electrolyte,
  allergy,
  hormone,
  liver,
  kidney,
  gut,
  tumor,
  coagulation,
  inflammation,
  infection,
  urine,
}

enum RecordKind { profile, result, medication, measurement }

enum ResultValueKind { numeric, comparison, qualitative, missing }

final class InvalidRecord implements Exception {
  const InvalidRecord(this.field);
  final String field;
}

void _required(String value, String field) {
  if (value.trim().isEmpty) throw InvalidRecord(field);
}

/// Keeps source precision, decimal separator and comparison operator intact.
final class SourceValue {
  const SourceValue(this.raw, this.kind);
  final String raw;
  final ResultValueKind kind;

  void validate() {
    final value = raw.trim();
    final number = r'[+-]?\d+(?:[.,]\d+)?';
    final valid = switch (kind) {
      ResultValueKind.numeric => RegExp('^$number\$').hasMatch(value),
      ResultValueKind.comparison => RegExp(
        '^(?:[<>]=?|[≤≥])\\s*$number\$',
      ).hasMatch(value),
      ResultValueKind.qualitative => value.isNotEmpty,
      ResultValueKind.missing => true,
    };
    if (!valid) throw const InvalidRecord('value');
  }
}

sealed class HealthRecord {
  const HealthRecord({required this.id, required this.profileId});
  final String id;
  final String profileId;
  RecordKind get kind;
  void validate() {
    _required(id, 'id');
    _required(profileId, 'profileId');
  }
}

final class MedicalProfile extends HealthRecord {
  const MedicalProfile({
    required super.id,
    required this.name,
    this.birthDate,
    this.history = '',
    this.allergies = '',
    this.notes = '',
  }) : super(profileId: id);
  final String name;
  final CalendarDate? birthDate;
  final String history, allergies, notes;
  @override
  RecordKind get kind => RecordKind.profile;
  @override
  void validate() {
    super.validate();
    _required(name, 'name');
  }
}

/// Manual entry is an explicit confirmation by the user. Source text is not
/// normalized or automatically merged with other laboratory results.
final class LabResult extends HealthRecord {
  const LabResult({
    required super.id,
    required super.profileId,
    required this.name,
    required this.value,
    required this.date,
    required this.category,
    this.unit = '',
    this.reference = '',
    this.laboratory = '',
    this.method = '',
    this.specimen = '',
    this.notes = '',
  });
  final String name, unit, reference, laboratory, method, specimen, notes;
  final SourceValue value;
  final CalendarDate date;
  final AnalysisCategory category;
  @override
  RecordKind get kind => RecordKind.result;
  @override
  void validate() {
    super.validate();
    _required(name, 'name');
    value.validate();
  }
}

final class MedicationCourse extends HealthRecord {
  const MedicationCourse({
    required super.id,
    required super.profileId,
    required this.name,
    required this.start,
    this.end,
    this.dosage = '',
    this.schedule = '',
    this.prescribedBy = '',
    this.notes = '',
  });
  final String name, dosage, schedule, prescribedBy, notes;
  final CalendarDate start;
  final CalendarDate? end;
  bool activeOn(CalendarDate date) =>
      start.compareTo(date) <= 0 && (end == null || end!.compareTo(date) >= 0);
  @override
  RecordKind get kind => RecordKind.medication;
  @override
  void validate() {
    super.validate();
    _required(name, 'name');
    if (end != null && end!.compareTo(start) < 0) {
      throw const InvalidRecord('end');
    }
  }
}

/// Date-only observations stay date-only. An optional clock time is paired
/// with its explicit UTC offset; it is never silently interpreted as UTC.
final class HomeMeasurement extends HealthRecord {
  const HomeMeasurement({
    required super.id,
    required super.profileId,
    required this.name,
    required this.value,
    required this.date,
    this.unit = '',
    this.source = '',
    this.minuteOfDay,
    this.utcOffsetMinutes,
    this.notes = '',
  });
  final String name, unit, source, notes;
  final SourceValue value;
  final CalendarDate date;
  final int? minuteOfDay, utcOffsetMinutes;
  @override
  RecordKind get kind => RecordKind.measurement;
  @override
  void validate() {
    super.validate();
    _required(name, 'name');
    value.validate();
    if ((minuteOfDay == null) != (utcOffsetMinutes == null) ||
        (minuteOfDay != null && (minuteOfDay! < 0 || minuteOfDay! >= 1440)) ||
        (utcOffsetMinutes != null && utcOffsetMinutes!.abs() > 14 * 60)) {
      throw const InvalidRecord('time');
    }
  }
}

final class RecordEntry {
  const RecordEntry(this.record, this.revision, {this.deleted = false});
  final HealthRecord record;
  final int revision;
  final bool deleted;
}

final class RecordConflict implements Exception {
  const RecordConflict();
}

final class OperationMismatch implements Exception {
  const OperationMismatch();
}

/// operationId identifies one immutable command, including its base revision.
final class RecordMutation {
  const RecordMutation({
    required this.operationId,
    required this.record,
    required this.expectedRevision,
    this.delete = false,
  });
  final String operationId;
  final HealthRecord record;
  final int expectedRevision;
  final bool delete;
}

abstract interface class HealthRecordsRepository {
  Future<List<RecordEntry>> read(String profileId);
  Future<List<RecordEntry>> history(String profileId, String recordId);
  Future<int> commit(RecordMutation mutation);
  Future<void> close();
}

/// Shared scenario used by every UI command; no platform dependencies.
final class HealthRecords {
  const HealthRecords(this.repository);
  final HealthRecordsRepository repository;
  Future<int> save(RecordMutation mutation) {
    mutation.record.validate();
    _required(mutation.operationId, 'operationId');
    if (mutation.expectedRevision < 0) {
      throw const InvalidRecord('revision');
    }
    return repository.commit(mutation);
  }
}
