import 'dart:convert';

import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> wire(HealthRecord r) =>
      jsonDecode(jsonEncode(encodeRecord(r))) as Map<String, dynamic>;
  test('legacy profile command remains byte stable and format 4 keeps original context', () {
    const old = MedicalProfile(
      id: 'p',
      name: 'Synthetic',
      history: 'Original free text',
      allergies: 'Original allergy',
      notes: 'Original note',
    );
    final before = encodeRecord(old);
    expect(before, {
      'format': 1,
      'id': 'p',
      'profileId': 'p',
      'kind': 'profile',
      'source': 'manual',
      'name': 'Synthetic',
      'birthDate': null,
      'history': 'Original free text',
      'allergies': 'Original allergy',
      'notes': 'Original note',
    });
    final profile = old.copyWith(
      details: ProfileDetails(
        fields: {ProfileField.height: '178,00', ProfileField.hips: '100.50'},
        history: [
          ProfileHistoryEntry(
            id: 'year',
            kind: ProfileHistoryKind.surgery,
            text: 'Source operation',
            precision: HistoryDatePrecision.year,
            year: 2001,
          ),
          const ProfileHistoryEntry(
            id: 'childhood',
            kind: ProfileHistoryKind.family,
            text: 'Source family history',
            precision: HistoryDatePrecision.childhood,
          ),
        ],
        events: [
          ProfileEvent(
            id: 'a',
            kind: ProfileEventKind.illness,
            name: 'Same source name',
            start: CalendarDate(2026, 1, 2),
            fields: {
              ProfileEventField.temperature: '38,20',
              ProfileEventField.antibiotics: 'Original old detail',
            },
          ),
          ProfileEvent(
            id: 'b',
            kind: ProfileEventKind.illness,
            name: 'Same source name',
            start: CalendarDate(2026, 1, 2),
          ),
        ],
      ),
    );
    final encoded = wire(profile);
    expect(encoded['format'], 4);
    final restored = decodeRecord(encoded) as MedicalProfile;
    expect(restored.history, old.history);
    expect(restored.allergies, old.allergies);
    expect(restored.notes, old.notes);
    expect(restored.details![ProfileField.height], '178,00');
    expect(restored.details![ProfileField.hips], '100.50');
    expect(restored.details!.history.first.date, isNull);
    expect(restored.details!.history.first.year, 2001);
    expect(
      restored.details!.history.last.precision,
      HistoryDatePrecision.childhood,
    );
    expect(restored.details!.history.last.year, isNull);
    expect(restored.details!.events.map((e) => e.id), ['a', 'b']);
    expect(
      restored.details!.events.first.fields[ProfileEventField.temperature],
      '38,20',
    );
    expect(encodeRecord(restored), encodeRecord(profile));
    expect(encodeRecord(old), before);
  });
  test(
    'invalid temporal precision and unknown detail versions are rejected',
    () {
      final p = MedicalProfile(
        id: 'p',
        name: 'Synthetic',
        details: ProfileDetails(
          history: [
            const ProfileHistoryEntry(
              id: 'a',
              kind: ProfileHistoryKind.chronic,
              text: 'Source',
              precision: HistoryDatePrecision.year,
            ),
          ],
        ),
      );
      expect(p.validate, throwsA(isA<InvalidRecord>()));
      final j = wire(
        MedicalProfile(id: 'p', name: 'Synthetic', details: ProfileDetails()),
      );
      (j['details'] as Map)['version'] = 99;
      expect(() => decodeRecord(j), throwsFormatException);
    },
  );
  test('medication reason and experience use version 4 without changing old courses', () {
    final old = MedicationCourse(
      id: 'm',
      profileId: 'p',
      name: 'Synthetic medicine',
      start: CalendarDate(2026, 1, 1),
    );
    expect(encodeRecord(old)['format'], 1);
    for (final regimen in MedicationRegimen.values) {
      final course = MedicationCourse(
        id: 'mode',
        profileId: 'p',
        name: 'Synthetic',
        start: old.start,
        regimen: regimen,
      );
      expect(encodeRecord(course)['format'], 4);
      expect((decodeRecord(wire(course)) as MedicationCourse).regimen, regimen);
    }
    final current = MedicationCourse(
      id: 'm',
      profileId: 'p',
      name: old.name,
      start: old.start,
      reason: 'Source reason',
      experience: MedicationExperience.repeatCourse,
    );
    final restored = decodeRecord(wire(current)) as MedicationCourse;
    expect(restored.reason, 'Source reason');
    expect(restored.experience, MedicationExperience.repeatCourse);
    expect(
      () => decodeRecord({...wire(current), 'format': 99}),
      throwsFormatException,
    );
  });
}
