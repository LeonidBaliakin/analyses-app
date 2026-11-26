import 'package:medical_terminology/medical_terminology.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reviewed HbA1c, free T4, TSH and CRP formulations resolve across sources',
    () {
      final cases = [
        ('helix', '06-014', 'Гликированный гемоглобин (HbA1c)', 'test.hba1c'),
        ('invitro', '18', 'HbA1c (гликированный Hb)', 'test.hba1c'),
        ('sova', null, 'Гликированный гемоглобин А1с', 'test.hba1c'),
        ('invitro', '55', 'Тироксин свободный (Т4 свободный)', 'test.free-t4'),
        ('invitro', '56', 'Тиреотропный гормон (ТТГ, тиротропин)', 'test.tsh'),
        ('invitro', '43', 'С-реактивный белок (СРБ)', 'test.crp'),
        (
          'helix',
          '06-182',
          'С-реактивный белок, количественно (метод с нормальной чувствительностью)',
          'test.crp',
        ),
      ];
      for (final (source, code, text, type) in cases) {
        final mapping = bundledLaboratoryTests.resolve(
          sourceSystem: source,
          sourceText: text,
          sourceCode: code,
        );
        expect(mapping?.conceptId, type, reason: text);
        expect(
          bundledLaboratoryTests.resolve(
            sourceSystem: 'another-lab',
            sourceText: text,
            sourceCode: code,
          ),
          isNull,
        );
      }
    },
  );

  test('a different specimen, fraction, method or panel is never inferred from similar words or codes', () {
    for (final (code, text) in [
      ('08-116', 'Тироксин общий (Т4 общий)'),
      ('06-014', 'Гемоглобин'),
      ('06-182', 'С-реактивный белок, высокочувствительный'),
      ('02-005', 'Клинический анализ крови с лейкоцитарной формулой и СОЭ'),
      ('07-009', 'РНК вируса гепатита C'),
    ]) {
      expect(
        bundledLaboratoryTests.resolve(
          sourceSystem: 'helix',
          sourceText: text,
          sourceCode: code,
        ),
        isNull,
        reason: text,
      );
    }
    expect(
      bundledLaboratoryTests
          .resolve(sourceSystem: 'sova', sourceText: 'Глюкоза')
          ?.conceptId,
      'test.sova.glucose',
    );
    expect(
      bundledLaboratoryTests.resolve(
        sourceSystem: 'sova',
        sourceText: 'Глюкоза в моче',
      ),
      isNull,
    );
  });
  test(
    'confirmed coagulation panels compare their complete component sets',
    () {
      final release = bundledLaboratoryTests;
      final sova = release.resolve(
        sourceSystem: 'sova',
        sourceText: 'Коагулограмма',
      )!;
      final inv = release.resolve(
        sourceSystem: 'invitro',
        sourceText: 'Гемостазиограмма (коагулограмма), скрининг',
        sourceCode: 'ОБС103',
      )!;
      expect(inv.conceptId, sova.conceptId);
      expect(sova.specification!.components, hasLength(4));
      final six = release.resolve(
        sourceSystem: 'invitro',
        sourceText: 'Гемостазиограмма (коагулограмма) расширенная',
        sourceCode: 'ОБС104',
      )!;
      final seven = release.resolve(
        sourceSystem: 'invitro',
        sourceText: 'Гемостазиограмма (коагулограмма) расширенная',
        sourceCode: 'ОБС109',
      )!;
      expect(six.conceptId, isNot(seven.conceptId));
      expect(six.specification!.components, hasLength(6));
      expect(
        seven.specification!.components.keys,
        contains('component.plasminogen'),
      );
      expect(
        release.resolve(sourceSystem: 'invitro', sourceText: seven.sourceText),
        isNull,
      );
      expect(
        () => LaboratoryTestRelease(
          id: 'incomplete',
          concepts: release.concepts,
          mappings: [
            LaboratoryTestMapping(
              id: 'wrong',
              sourceSystem: 'synthetic',
              sourceText: 'Synthetic panel',
              conceptId: six.conceptId,
              source: sova.source,
              checkedAt: sova.checkedAt,
              specification: sova.specification,
            ),
          ],
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'specimens and methods are retained without pretending ESR methods agree',
    () {
      final release = bundledLaboratoryTests;
      final glucose = release.resolve(
        sourceSystem: 'sova',
        sourceText: 'Глюкоза',
      )!;
      expect(glucose.specification!.specimenText, 'Венозная кровь');
      expect(glucose.specification!.methodText, isNull);
      expect(
        release
            .resolve(
              sourceSystem: 'helix',
              sourceText: 'Глюкоза в плазме',
              sourceCode: '06-015',
            )!
            .conceptId,
        glucose.conceptId,
      );
      final photo = release.resolve(
        sourceSystem: 'helix',
        sourceText: 'Скорость оседания эритроцитов (СОЭ)',
        sourceCode: '02-007',
      )!;
      expect(photo.conceptId, 'test.esr-capillary-photometry');
      expect(photo.conceptId, isNot('test.esr-westergren'));
      expect(photo.specification!.methodText, contains('фотометрии'));
    },
  );
  test(
    'reviewed provider formulations share a type and retain their source',
    () {
      final release = bundledLaboratoryTests;
      final short = release.resolve(
        sourceSystem: 'sova',
        sourceText: 'Общий анализ мочи',
      )!;
      final reversed = release.resolve(
        sourceSystem: 'scandinavia',
        sourceText: 'Анализ мочи общий',
      )!;
      final microscopy = release.resolve(
        sourceSystem: 'helix',
        sourceText: 'Общий анализ мочи с микроскопией',
        sourceCode: '02-006',
      )!;
      expect(
        {short.conceptId, reversed.conceptId, microscopy.conceptId},
        {'test.urinalysis'},
      );
      expect(short.sourceText, 'Общий анализ мочи');
      expect(reversed.sourceText, 'Анализ мочи общий');
      expect(microscopy.sourceCode, '02-006');
      expect(microscopy.source.host, 'helix.ru');
      expect(microscopy.checkedAt, DateTime(2026, 11, 26));
      expect(release.searchText(short.conceptId), contains('ОАМ'));
      expect(release.id, isNotEmpty);
    },
  );

  test('unknown sources, changed codes, other urine tests and ambiguous links stay unknown', () {
    final release = bundledLaboratoryTests;
    expect(
      release.resolve(sourceSystem: 'unknown', sourceText: 'Общий анализ мочи'),
      isNull,
    );
    expect(
      release.resolve(
        sourceSystem: 'helix',
        sourceText: 'Общий анализ мочи с микроскопией',
        sourceCode: 'other',
      ),
      isNull,
    );
    for (final name in [
      'Анализ мочи по Нечипоренко',
      'Посев мочи',
      'Глюкоза в моче',
    ]) {
      expect(release.resolve(sourceSystem: 'sova', sourceText: name), isNull);
    }
    final mapping = release.mappings.first;
    final ambiguous = LaboratoryTestRelease(
      id: 'ambiguous',
      concepts: release.concepts,
      mappings: [
        mapping,
        LaboratoryTestMapping(
          id: 'conflict',
          sourceSystem: mapping.sourceSystem,
          sourceText: mapping.sourceText,
          sourceCode: mapping.sourceCode,
          conceptId: 'test.ferritin',
          source: mapping.source,
          checkedAt: mapping.checkedAt,
        ),
      ],
    );
    expect(
      ambiguous.resolve(
        sourceSystem: mapping.sourceSystem,
        sourceText: mapping.sourceText,
        sourceCode: mapping.sourceCode,
      ),
      isNull,
    );
  });

  test('broader and proposed links are excluded; invalid targets reject the release', () {
    final concepts = bundledLaboratoryTests.concepts;
    LaboratoryTestMapping mapping({
      String target = 'test.urinalysis',
      MappingRelation relation = MappingRelation.exact,
      MappingVerification verification = MappingVerification.curated,
    }) => LaboratoryTestMapping(
      id: 'synthetic',
      sourceSystem: 'synthetic',
      sourceText: 'Synthetic urine test',
      conceptId: target,
      source: Uri.parse('https://example.org/test'),
      checkedAt: DateTime(2026),
      relation: relation,
      verification: verification,
    );
    for (final m in [
      mapping(relation: MappingRelation.broader),
      mapping(verification: MappingVerification.proposed),
    ]) {
      final release = LaboratoryTestRelease(
        id: 'synthetic',
        concepts: concepts,
        mappings: [m],
      );
      expect(
        release.resolve(sourceSystem: 'synthetic', sourceText: m.sourceText),
        isNull,
      );
    }
    expect(
      () => LaboratoryTestRelease(
        id: 'invalid',
        concepts: concepts,
        mappings: [mapping(target: 'missing')],
      ),
      throwsFormatException,
    );
  });
}
