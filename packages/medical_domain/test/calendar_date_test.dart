import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

void main() {
  test('keeps a date without adding a time zone or time of day', () {
    final date = CalendarDate.parse('2026-11-24');
    expect(date, CalendarDate(2026, 11, 24));
    expect(date.toString(), '2026-11-24');
    expect({date, CalendarDate(2026, 11, 24)}, hasLength(1));
  });

  test('validates Gregorian leap years rather than normalizing dates', () {
    expect(CalendarDate(2000, 2, 29).day, 29);
    expect(CalendarDate(2024, 2, 29).day, 29);
    for (final value in [
      '1900-02-29',
      '2026-02-29',
      '2026-04-31',
      '2026-00-01',
      '0000-01-01',
    ]) {
      expect(() => CalendarDate.parse(value), throwsFormatException);
    }
  });

  test('rejects partial dates, times and noncanonical formats', () {
    for (final value in [
      '2026',
      '2026-11',
      '2026-1-01',
      '2026-11-24T00:00:00Z',
      ' 2026-11-24',
    ]) {
      expect(() => CalendarDate.parse(value), throwsFormatException);
    }
  });

  test('compares across month and year boundaries', () {
    final dates = [
      CalendarDate(2027, 1, 1),
      CalendarDate(2026, 12, 31),
      CalendarDate(2026, 1, 1),
    ]..sort();
    expect(dates.map((date) => date.toString()), [
      '2026-01-01',
      '2026-12-31',
      '2027-01-01',
    ]);
  });
}
