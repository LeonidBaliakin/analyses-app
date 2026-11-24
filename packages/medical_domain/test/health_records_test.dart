import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

void main() {
  test('source precision, separator and operator are retained', () {
    for (final (raw, kind) in [
      ('0,0100', ResultValueKind.numeric),
      ('< 0,0100', ResultValueKind.comparison),
      ('≤0.0100', ResultValueKind.comparison),
      ('не обнаружено', ResultValueKind.qualitative),
      ('', ResultValueKind.missing),
    ]) {
      final value = SourceValue(raw, kind);
      value.validate();
      expect(value.raw, raw);
    }
    expect(
      () => const SourceValue('', ResultValueKind.numeric).validate(),
      throwsA(isA<InvalidRecord>()),
    );
    expect(
      () => const SourceValue(
        'не обнаружено',
        ResultValueKind.numeric,
      ).validate(),
      throwsA(isA<InvalidRecord>()),
    );
    expect(
      () => const SourceValue('0', ResultValueKind.comparison).validate(),
      throwsA(isA<InvalidRecord>()),
    );
  });
  test(
    'course includes both boundaries and can start before selected period',
    () {
      final course = MedicationCourse(
        id: 'c',
        profileId: 'p',
        name: 'Synthetic',
        start: CalendarDate(2025, 1, 1),
        end: CalendarDate(2026, 11, 24),
      );
      expect(course.activeOn(CalendarDate(2026, 11, 24)), isTrue);
      expect(course.activeOn(CalendarDate(2025, 1, 1)), isTrue);
      expect(course.activeOn(CalendarDate(2026, 11, 25)), isFalse);
      expect(course.activeOn(CalendarDate(2024, 12, 31)), isFalse);
      expect(
        () => MedicationCourse(
          id: 'c',
          profileId: 'p',
          name: 'Synthetic',
          start: CalendarDate(2026, 2, 1),
          end: CalendarDate(2026, 1, 31),
        ).validate(),
        throwsA(isA<InvalidRecord>()),
      );
    },
  );
  test(
    'date-only measurement is distinct from time with an explicit offset',
    () {
      HomeMeasurement measurement({int? time, int? offset}) => HomeMeasurement(
        id: 'm',
        profileId: 'p',
        name: 'Synthetic',
        date: CalendarDate(2026, 11, 24),
        value: const SourceValue('120/80', ResultValueKind.qualitative),
        minuteOfDay: time,
        utcOffsetMinutes: offset,
      );
      measurement().validate();
      measurement(time: 23 * 60 + 59, offset: 180).validate();
      expect(
        () => measurement(time: 720).validate(),
        throwsA(isA<InvalidRecord>()),
      );
      expect(
        () => measurement(time: 1440, offset: 0).validate(),
        throwsA(isA<InvalidRecord>()),
      );
      expect(
        () => measurement(time: 720, offset: 841).validate(),
        throwsA(isA<InvalidRecord>()),
      );
    },
  );
}
