import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/records/src/result_coding_view_model.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

void main() {
  late ResultCodingViewModel model;
  setUp(() => model = ResultCodingViewModel(bundledTerminology));
  tearDown(() => model.dispose());

  void source({
    String name = 'HGB',
    String unit = 'г/л',
    String laboratory = '',
    String specimen = '',
    String method = '',
  }) => model.updateSource(
    name: name,
    unit: unit,
    laboratory: laboratory,
    specimen: specimen,
    method: method,
  );

  test('a unique suggestion stays unlinked until explicit user choice', () {
    source();
    expect(model.matches.status, MatchStatus.unique);
    expect(model.coding, isNull);
    model.selectIndicator('indicator.hemoglobin.blood');
    expect(model.coding!.unitId, isNull);
    model.selectUnit('unit.g-per-l');
    expect(model.coding!.sourceName, 'HGB');
    expect(model.coding!.sourceUnit, 'г/л');
    expect(model.coding!.unitId, 'unit.g-per-l');
    expect(
      () => model.selectUnit('unit.mmol-per-l'),
      throwsA(isA<InvalidRecord>()),
    );
  });

  test('editing source context clears a selection; changing it back does not restore it', () {
    for (final update in [
      () => source(name: 'changed'),
      () => source(unit: 'changed'),
      () => source(laboratory: 'changed'),
      () => source(specimen: 'changed'),
      () => source(method: 'changed'),
    ]) {
      source();
      model.selectIndicator('indicator.hemoglobin.blood');
      update();
      expect(model.coding, isNull);
      expect(model.invalidated, isTrue);
      source();
      expect(model.coding, isNull);
    }
  });

  test('unchanged historical selection survives even if its release is unavailable', () {
    const old = LabResultCoding(
      terminologyReleaseId: 'older-release',
      indicatorId: 'older-concept',
      unitId: 'older-unit',
      sourceName: 'HGB',
      sourceUnit: 'г/л',
      sourceLaboratory: '',
      sourceSpecimen: '',
      sourceMethod: '',
    );
    final historical = ResultCodingViewModel(bundledTerminology, initial: old);
    addTearDown(historical.dispose);
    historical.updateSource(
      name: 'HGB',
      unit: 'г/л',
      laboratory: '',
      specimen: '',
      method: '',
    );
    expect(historical.coding, same(old));
    historical.selectIndicator('');
    expect(historical.coding, isNull);
  });

  test('unknown and ambiguous names are never silently attached', () {
    source(name: 'Glucose', unit: '');
    expect(model.matches.status, MatchStatus.ambiguous);
    expect(model.coding, isNull);
    source(name: 'unknown', unit: 'unknown');
    expect(model.matches.status, MatchStatus.unknown);
    expect(model.coding, isNull);
  });
}
