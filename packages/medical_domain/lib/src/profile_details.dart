import 'calendar_date.dart';

/// User-entered context; raw decimal and descriptive text is retained.
/// These fields do not select reference ranges or infer diagnoses.
enum ProfileField {
  sex,
  height,
  waist,
  hips,
  chest,
  cycle,
  city,
  travel,
  activity,
  sport,
  foodNotes,
  stress,
  sleep,
  diet,
  smoking,
  packsPerDay,
  smokingQuitPrecision,
  smokingQuitDate,
  smokingQuitYear,
  alcohol,
  alcoholAmount,
  alcoholQuitPrecision,
  alcoholQuitDate,
  alcoholQuitYear,
}

enum ProfileHistoryKind { chronic, surgery, family, other }

enum HistoryDatePrecision { unknown, date, year, childhood }

final class ProfileHistoryEntry {
  const ProfileHistoryEntry({
    required this.id,
    required this.kind,
    required this.text,
    this.precision = HistoryDatePrecision.unknown,
    this.date,
    this.year,
  });
  final String id, text;
  final ProfileHistoryKind kind;
  final HistoryDatePrecision precision;
  final CalendarDate? date;
  final int? year;
  bool get isValid =>
      id.isNotEmpty &&
      text.trim().isNotEmpty &&
      (year == null || (year! >= 1000 && year! <= 9999)) &&
      switch (precision) {
        HistoryDatePrecision.unknown => date == null && year == null,
        HistoryDatePrecision.date => date != null && year == null,
        HistoryDatePrecision.year => year != null && date == null,
        HistoryDatePrecision.childhood => date == null,
      };
}

enum ProfileEventKind { complaint, illness, hospitalization, allergy }

enum ProfileEventField {
  sourceText,
  temperature,
  institution,
  outcomes,
  reaction,
  antibiotics,
}

/// Separate events have stable identities, even when their names are equal.
final class ProfileEvent {
  ProfileEvent({
    required this.id,
    required this.kind,
    required this.name,
    this.start,
    this.end,
    Map<ProfileEventField, String> fields = const {},
  }) : fields = Map.unmodifiable(fields);
  final String id, name;
  final ProfileEventKind kind;
  final CalendarDate? start, end;
  final Map<ProfileEventField, String> fields;
  bool get isValid =>
      id.isNotEmpty &&
      name.trim().isNotEmpty &&
      (end == null || (start != null && end!.compareTo(start!) >= 0));
}

final class ProfileDetails {
  ProfileDetails({
    Map<ProfileField, String> fields = const {},
    Iterable<ProfileHistoryEntry> history = const [],
    Iterable<ProfileEvent> events = const [],
  }) : fields = Map.unmodifiable(fields),
       history = List.unmodifiable(history),
       events = List.unmodifiable(events);
  final Map<ProfileField, String> fields;
  final List<ProfileHistoryEntry> history;
  final List<ProfileEvent> events;
  String operator [](ProfileField field) => fields[field] ?? '';
  ProfileDetails copyWith({
    Map<ProfileField, String>? fields,
    Iterable<ProfileHistoryEntry>? history,
    Iterable<ProfileEvent>? events,
  }) => ProfileDetails(
    fields: fields ?? this.fields,
    history: history ?? this.history,
    events: events ?? this.events,
  );
  bool get isValid =>
      history.every((e) => e.isValid) &&
      events.every((e) => e.isValid) &&
      history.map((e) => e.id).toSet().length == history.length &&
      events.map((e) => e.id).toSet().length == events.length;
}

enum MedicationExperience { firstCourse, repeatCourse, unknown }
