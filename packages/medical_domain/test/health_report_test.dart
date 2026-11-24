import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

LabResult result(
  String id,
  String date, {
  String profile = 'p',
  String value = '0,0100',
  String lab = 'A',
  String method = 'Synthetic method',
  String specimen = 'Synthetic material',
  String unit = 'г/л',
  String? unitId = 'u',
  bool coded = true,
}) => LabResult(
  id: id,
  profileId: profile,
  name: 'Same name',
  date: CalendarDate.parse(date),
  value: SourceValue(
    value,
    value.startsWith('<')
        ? ResultValueKind.comparison
        : ResultValueKind.numeric,
  ),
  category: AnalysisCategory.blood,
  unit: unit,
  laboratory: lab,
  method: method,
  specimen: specimen,
  coding: coded
      ? LabResultCoding(
          terminologyReleaseId: 'r1',
          indicatorId: 'i1',
          unitId: unitId,
          sourceName: 'Same name',
          sourceUnit: unit,
          sourceLaboratory: lab,
          sourceSpecimen: specimen,
          sourceMethod: method,
        )
      : null,
);
void main() {
  test('inclusive dates and overlapping courses preserve source values and ownership', () {
    final period = ReportPeriod(
      CalendarDate(2026, 11, 1),
      CalendarDate(2026, 11, 30),
    );
    final report = HealthReport.build(
      [
        const RecordEntry(MedicalProfile(id: 'p', name: 'Synthetic'), 1),
        for (final r in [
          result('old', '2026-10-31'),
          result('first', '2026-11-01'),
          result('last', '2026-11-30', value: '< 0,0100'),
          result('future', '2026-12-01'),
          result('foreign', '2026-11-10', profile: 'q'),
        ])
          RecordEntry(r, 1),
        RecordEntry(result('deleted', '2026-11-11'), 2, deleted: true),
        RecordEntry(
          MedicationCourse(
            id: 'overlap',
            profileId: 'p',
            name: 'Course',
            start: CalendarDate(2026, 10, 1),
            end: CalendarDate(2026, 11, 1),
          ),
          1,
        ),
        RecordEntry(
          MedicationCourse(
            id: 'ended',
            profileId: 'p',
            name: 'Course',
            start: CalendarDate(2026, 10, 1),
            end: CalendarDate(2026, 10, 31),
          ),
          1,
        ),
        RecordEntry(
          MedicationCourse(
            id: 'ongoing',
            profileId: 'p',
            name: 'Course',
            start: CalendarDate(2026, 10, 1),
          ),
          1,
        ),
        RecordEntry(
          HomeMeasurement(
            id: 'measure',
            profileId: 'p',
            name: 'Synthetic',
            date: CalendarDate(2026, 11, 30),
            value: const SourceValue('negative', ResultValueKind.qualitative),
            minuteOfDay: 15,
            utcOffsetMinutes: 180,
          ),
          1,
        ),
      ],
      'p',
      period,
    );
    expect(report.results.map((r) => r.id), ['last', 'first']);
    expect(report.results.first.value.raw, '< 0,0100');
    expect(report.medications.map((r) => r.id).toSet(), {'overlap', 'ongoing'});
    expect(report.measurements.single.minuteOfDay, 15);
    expect(report.series.single.previous!.id, 'first');
    expect(
      () => ReportPeriod(period.end, period.start),
      throwsA(isA<InvalidRecord>()),
    );
  });
  test('names, unknown units, different sources and same-day observations do not invent a trend', () {
    final report = HealthReport.build(
      [
        for (final r in [
          result('a', '2026-11-02'),
          result('b', '2026-11-02'),
          result('c', '2026-11-01'),
          result('lab', '2026-11-03', lab: 'B'),
          result('unit', '2026-11-03', unit: 'mg/L', unitId: 'mg'),
          result('unknown', '2026-11-03', unitId: null),
          result('unlinked1', '2026-11-03', coded: false),
          result('unlinked2', '2026-11-03', coded: false),
          result('context1', '2026-11-03', method: ''),
          result('context2', '2026-11-02', method: ''),
        ])
          RecordEntry(r, 1),
      ],
      'p',
      ReportPeriod(CalendarDate(2026, 11, 1), CalendarDate(2026, 11, 30)),
    );
    expect(report.series, hasLength(8));
    final series = report.series.singleWhere((s) => s.results.length == 3);
    expect(series.previous, isNull);
    expect(series.latestOnDate.map((r) => r.id), ['a', 'b']);
    expect(report.results.map((r) => r.value.raw), everyElement('0,0100'));
  });
}
