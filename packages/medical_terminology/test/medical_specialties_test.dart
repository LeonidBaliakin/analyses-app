import 'package:medical_terminology/medical_terminology.dart';
import 'package:test/test.dart';

void main() {
  test('source formulations resolve to one specialty with provenance', () {
    final release = bundledMedicalSpecialties;
    final surgeon = release.resolve(
      sourceSystem: 'smclinic',
      sourceText: 'Хирург',
    )!;
    final physician = release.resolve(
      sourceSystem: 'sova',
      sourceText: 'Врач-хирург',
    )!;
    expect(surgeon.conceptId, physician.conceptId);
    expect(physician.source.host, 'voronezh.sovamed.ru');
    expect(physician.checkedAt, DateTime(2026, 11, 27));
    expect(
      release
          .resolve(
            sourceSystem: 'sova',
            sourceText: '  ВРАЧ — АКУШЕР-ГИНЕКОЛОГ  ',
          )
          ?.conceptId,
      'specialty.obstetrics-gynecology',
    );
    expect(release.searchText(surgeon.conceptId), contains('Surgeon'));
  });
  test(
    'source scope, child specialties and distinct qualifications are preserved',
    () {
      final release = bundledMedicalSpecialties;
      expect(
        release.resolve(sourceSystem: 'unknown', sourceText: 'Врач-хирург'),
        isNull,
      );
      for (final name in [
        'Детский невролог',
        'Психолог',
        'Руководитель центра неврологии',
        'Врач-невролог, Врач-психиатр',
      ]) {
        expect(release.resolve(sourceSystem: 'sova', sourceText: name), isNull);
      }
      expect(
        release
            .resolve(
              sourceSystem: 'smclinic',
              sourceText: 'Пластический хирург',
            )
            ?.conceptId,
        isNot('specialty.surgery'),
      );
      final first = release.mappings.first;
      final ambiguous = MedicalSpecialtyRelease(
        id: 'synthetic',
        concepts: release.concepts,
        mappings: [
          first,
          MedicalSpecialtyMapping(
            id: 'conflict',
            sourceSystem: first.sourceSystem,
            sourceText: first.sourceText,
            conceptId: 'specialty.surgery',
            source: first.source,
            checkedAt: first.checkedAt,
          ),
        ],
      );
      expect(
        ambiguous.resolve(
          sourceSystem: first.sourceSystem,
          sourceText: first.sourceText,
        ),
        isNull,
      );
      final proposed = MedicalSpecialtyRelease(
        id: 'proposed',
        concepts: release.concepts,
        mappings: [
          MedicalSpecialtyMapping(
            id: 'p',
            sourceSystem: first.sourceSystem,
            sourceText: first.sourceText,
            conceptId: first.conceptId,
            source: first.source,
            checkedAt: first.checkedAt,
            verification: MappingVerification.proposed,
          ),
        ],
      );
      expect(
        proposed.resolve(
          sourceSystem: first.sourceSystem,
          sourceText: first.sourceText,
        ),
        isNull,
      );
    },
  );
}
