import 'package:medical_domain/medical_domain.dart';
import 'package:test/test.dart';

void main() {
  const coding = LabResultCoding(
    terminologyReleaseId: 'synthetic-v1',
    indicatorId: 'synthetic-indicator',
    unitId: 'synthetic-unit',
    sourceName: 'Original name',
    sourceUnit: 'Original unit',
    sourceLaboratory: 'Original lab',
    sourceSpecimen: 'Original specimen',
    sourceMethod: 'Original method',
  );
  LabResult result({
    String name = 'Original name',
    String unit = 'Original unit',
    String laboratory = 'Original lab',
    String specimen = 'Original specimen',
    String method = 'Original method',
    LabResultCoding? binding = coding,
  }) => LabResult(
    id: 'result',
    profileId: 'profile',
    name: name,
    unit: unit,
    laboratory: laboratory,
    specimen: specimen,
    method: method,
    coding: binding,
    value: const SourceValue('< 0,0100', ResultValueKind.comparison),
    category: AnalysisCategory.blood,
    date: CalendarDate(2026, 11, 24),
  );

  test('original precision and reference context survive an association', () {
    final r = result();
    r.validate();
    expect(r.value.raw, '< 0,0100');
    expect(r.name, 'Original name');
    expect(r.coding!.sourceUnit, r.unit);
  });

  test('source edits invalidate stale associations at the domain boundary', () {
    for (final r in [
      result(name: 'changed'),
      result(unit: 'changed'),
      result(laboratory: 'changed'),
      result(specimen: 'changed'),
      result(method: 'changed'),
    ]) {
      expect(r.validate, throwsA(isA<InvalidRecord>()));
    }
    result(name: 'unknown', unit: '', binding: null).validate();
  });
}
