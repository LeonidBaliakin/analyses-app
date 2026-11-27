import 'package:document_processing/document_processing.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

void main() {
  var sequence = 0;
  String id() => 'e${sequence++}';
  final today = CalendarDate(2026, 1, 1);
  test('splits source sample, retains exact fragments, dates and uncertainty', () {
    const story =
        ' С 10.11.2026 болел ОРВИ, с 11.11.2026 принимал витамин D. Был в санатории. Вчера вес 82,00 кг; болел 3 мая';
    final rows = const EventCaptureParser().parse(
      story,
      today: today,
      newId: id,
    );
    expect(rows, hasLength(5));
    expect(rows[0].kind, CapturedEventKind.illness);
    expect(rows[1].kind, CapturedEventKind.medication);
    expect(rows[2].kind, CapturedEventKind.travel);
    for (final row in rows) {
      expect(story.substring(row.start, row.end), row.source);
    }
    expect(rows[0].fields['from'], '2026-11-10');
    expect(rows[3].fields['from'], '2025-12-31');
    expect(rows[3].fields['value'], '82,00');
    expect(rows[4].fields['from'], '');
    expect(rows[4].issue, 'missing_year');
  });
  test(
    'full named dates validate; missing and invalid dates never become today',
    () {
      final rows = const EventCaptureParser().parse(
        'Болел 3 мая 2026; болел 31.02.2026; болел',
        today: today,
        newId: id,
      );
      expect(rows[0].fields['from'], '2026-05-03');
      expect(rows[1].issue, 'invalid_date');
      expect(rows[1].fields['from'], '');
      expect(rows[2].fields['from'], '');
    },
  );
  test('confirmation preserves raw values and profile history, rejects incomplete draft', () {
    const profile = MedicalProfile(
      id: 'p',
      name: 'Synthetic',
      history: 'Original history',
    );
    final rows = const EventCaptureParser().parse(
      'Вчера вес 82,00 кг; болел вчера температура 38,60; принимал вчера витамин D',
      today: today,
      newId: id,
    );
    final records = confirmedEventRecords(rows, profile);
    expect(records, hasLength(3));
    final updated = records.first as MedicalProfile;
    expect(updated.history, profile.history);
    expect(
      updated.details!.events.single.fields[ProfileEventField.temperature],
      '38,60',
    );
    expect(
      updated.details!.events.single.fields[ProfileEventField.sourceText],
      contains(rows[1].source),
    );
    expect((records[1] as HomeMeasurement).value.raw, '82,00');
    expect(
      () => confirmedEventRecords([
        rows[0].edit(fields: {...rows[0].fields, 'from': ''}),
      ], profile),
      throwsA(isA<InvalidRecord>()),
    );
    expect(profile.details, isNull);
    expect(
      records.whereType<MedicationCourse>().single.regimen,
      MedicationRegimen.course,
    );
  });
  test(
    'changing section cannot save hidden dates or fields from the old kind',
    () {
      final rows = const EventCaptureParser().parse(
        'Болел вчера температура 38,6',
        today: today,
        newId: id,
      );
      final allergy = rows.single.edit(
        kind: CapturedEventKind.allergy,
        fields: {
          ...rows.single.fields,
          'reaction': 'Original reaction',
          'to': 'invalid old date',
        },
      );
      final profile =
          confirmedEventRecords([
                allergy,
              ], const MedicalProfile(id: 'p', name: 'Synthetic')).single
              as MedicalProfile;
      final event = profile.details!.events.single;
      expect(event.kind, ProfileEventKind.allergy);
      expect(event.start, isNull);
      expect(event.end, isNull);
      expect(event.fields.containsKey(ProfileEventField.temperature), isFalse);
      expect(event.fields[ProfileEventField.reaction], 'Original reaction');
    },
  );
}
