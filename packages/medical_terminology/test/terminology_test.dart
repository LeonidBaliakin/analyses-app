import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';
import 'package:test/test.dart';

TerminologyRelease release({
  String id = 'synthetic-v1',
  Iterable<TermAlias>? aliases,
}) => TerminologyRelease(
  id: id,
  source: 'Synthetic test fixture',
  usage: 'Tests only',
  indicators: bundledTerminology.active.indicators,
  units: bundledTerminology.active.units,
  indicatorAliases: aliases ?? bundledTerminology.active.indicatorAliases,
  unitAliases: bundledTerminology.active.unitAliases,
);

void main() {
  final pilot = bundledTerminology.active;

  test('ambiguous names require context; similarity never merges terms', () {
    expect(pilot.findIndicators('  ГЛЮКОЗА  ').status, MatchStatus.ambiguous);
    expect(pilot.findIndicators('Glucose', specimen: 'плазма').conceptIds, [
      'indicator.glucose.plasma',
    ]);
    expect(pilot.findIndicators('Глюкоза', specimen: 'urine').conceptIds, [
      'indicator.glucose.urine',
    ]);
    expect(
      pilot.findIndicators('Глюкоза', specimen: 'unknown specimen').status,
      MatchStatus.unknown,
    );
    expect(pilot.findIndicators('Glucos').status, MatchStatus.unknown);
    expect(pilot.findIndicators('').status, MatchStatus.unknown);
  });

  test('source mappings and methods never leak into other contexts', () {
    final scoped = release(
      aliases: [
        const TermAlias(
          id: 'a',
          text: 'Synthetic code',
          conceptId: 'indicator.glucose.plasma',
          sourceSystem: 'Lab A',
          method: 'Method A',
        ),
        const TermAlias(
          id: 'b',
          text: 'Synthetic code',
          conceptId: 'indicator.glucose.urine',
          sourceSystem: 'Lab B',
        ),
        const TermAlias(
          id: 'global',
          text: 'Synthetic code',
          conceptId: 'indicator.hemoglobin.blood',
        ),
      ],
    );
    expect(
      scoped
          .findIndicators(
            'Synthetic code',
            sourceSystem: 'Lab A',
            method: 'Method A',
          )
          .conceptIds,
      ['indicator.glucose.plasma'],
    );
    expect(
      scoped.findIndicators('Synthetic code', sourceSystem: 'Lab B').conceptIds,
      ['indicator.glucose.urine'],
    );
    expect(
      scoped.findIndicators('Synthetic code', sourceSystem: 'Lab C').conceptIds,
      ['indicator.hemoglobin.blood'],
    );
    expect(
      scoped
          .findIndicators(
            'Synthetic code',
            sourceSystem: 'Lab A',
            method: 'Other method',
          )
          .conceptIds,
      ['indicator.hemoglobin.blood'],
    );
  });

  test('broader and unreviewed mappings cannot become exact matches', () {
    final draft = release(
      aliases: const [
        TermAlias(
          id: 'broad',
          text: 'candidate',
          conceptId: 'indicator.glucose.plasma',
          relation: MappingRelation.broader,
        ),
        TermAlias(
          id: 'draft',
          text: 'candidate',
          conceptId: 'indicator.glucose.urine',
          verification: MappingVerification.proposed,
        ),
        TermAlias(
          id: 'guess',
          text: 'candidate',
          conceptId: 'indicator.creatinine.serum',
          relation: MappingRelation.proposed,
        ),
      ],
    );
    expect(draft.findIndicators('candidate').status, MatchStatus.unknown);
  });

  test('unit search respects case and unknown units stay unknown', () {
    expect(pilot.findUnits('ммоль/л').conceptIds, ['unit.mmol-per-l']);
    expect(pilot.findUnits(' µmol/L ').conceptIds, ['unit.umol-per-l']);
    expect(pilot.findUnits('g/L').conceptIds, ['unit.g-per-l']);
    for (final raw in ['', 'G/L', 'mmol/l', 'unknown', '%']) {
      expect(pilot.findUnits(raw).status, MatchStatus.unknown, reason: raw);
    }
    expect(
      pilot.findIndicators('Гемоглобин', unitId: 'unit.mmol-per-l').status,
      MatchStatus.unknown,
    );
  });

  test('explicit association keeps source text and permits unknown unit', () {
    final c = pilot.confirm(
      indicatorId: 'indicator.hemoglobin.blood',
      sourceName: '  HGB  ',
      sourceUnit: 'original unknown unit',
      sourceLaboratory: 'Synthetic lab',
      sourceSpecimen: 'source material',
      sourceMethod: 'source method',
    );
    expect(c.sourceName, '  HGB  ');
    expect(c.unitId, isNull);
    expect(c.terminologyReleaseId, pilot.id);
    expect(c.verification, 'userConfirmed');
    expect(c.scope, 'record');
    expect(c.relation, 'exact');
  });

  test('incompatible or missing units cannot be linked by guessing', () {
    LabResultCoding confirm(String? unitId, String sourceUnit) => pilot.confirm(
      indicatorId: 'indicator.hemoglobin.blood',
      unitId: unitId,
      sourceName: 'HGB',
      sourceUnit: sourceUnit,
      sourceLaboratory: '',
      sourceSpecimen: '',
      sourceMethod: '',
    );
    expect(
      () => confirm('unit.mmol-per-l', 'ммоль/л'),
      throwsA(isA<InvalidRecord>()),
    );
    expect(() => confirm('unit.g-per-l', ''), throwsA(isA<InvalidRecord>()));
    expect(confirm(null, '').unitId, isNull);
    expect(
      () => pilot.confirm(
        indicatorId: 'indicator.glucose.plasma',
        unitId: 'unit.mg-per-dl',
        sourceName: 'Glucose',
        sourceUnit: 'mmol/L',
        sourceLaboratory: '',
        sourceSpecimen: '',
        sourceMethod: '',
      ),
      throwsA(isA<InvalidRecord>()),
    );
  });

  test(
    'updates retain historical releases and immutable source associations',
    () {
      final coding = pilot.confirm(
        indicatorId: 'indicator.glucose.urine',
        sourceName: 'Glucose',
        sourceUnit: '',
        sourceLaboratory: '',
        sourceSpecimen: '',
        sourceMethod: '',
      );
      final next = release(id: 'synthetic-v2', aliases: []);
      final updated = TerminologyCatalog(
        releases: [pilot, next],
        activeReleaseId: next.id,
      );
      expect(
        updated.active.findIndicators('Glucose').status,
        MatchStatus.unknown,
      );
      expect(
        updated.releases[coding.terminologyReleaseId]!
            .findIndicators('Glucose')
            .status,
        MatchStatus.ambiguous,
      );
      expect(coding.indicatorId, 'indicator.glucose.urine');
      expect(() => pilot.indicators.clear(), throwsUnsupportedError);
      expect(
        () => pilot.indicators.first.unitIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => updated.releases.clear(), throwsUnsupportedError);
    },
  );

  test('incomplete, duplicate or unsupported releases fail before use', () {
    expect(
      () => release(
        aliases: const [TermAlias(id: 'bad', text: 'x', conceptId: 'absent')],
      ),
      throwsFormatException,
    );
    expect(
      () => TerminologyCatalog(
        releases: [pilot, pilot],
        activeReleaseId: pilot.id,
      ),
      throwsFormatException,
    );
    expect(
      () => TerminologyCatalog(releases: [pilot], activeReleaseId: 'absent'),
      throwsFormatException,
    );
    expect(
      () => TerminologyRelease(
        id: 'bad',
        schemaVersion: 2,
        source: 'fixture',
        usage: 'test',
        indicators: [],
        units: [],
        indicatorAliases: [],
        unitAliases: [],
      ),
      throwsFormatException,
    );
  });
}
