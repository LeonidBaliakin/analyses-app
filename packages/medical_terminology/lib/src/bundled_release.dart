import 'terminology.dart';

/// Small project-authored pilot set, not an imported clinical classification.
/// No external codes, reference ranges or conversion factors are asserted.
final bundledTerminology = TerminologyCatalog(
  activeReleaseId: 'analyses-pilot-2026-11-24.1',
  releases: [
    TerminologyRelease(
      id: 'analyses-pilot-2026-11-24.1',
      source: 'analyses-app: project-authored pilot vocabulary',
      usage: 'Internal pilot for explicit manual selection; no clinical validation or external mappings.',
      indicators: [
        IndicatorConcept(
          id: 'indicator.glucose.plasma',
          label: const TerminologyLabel(
            ru: 'Глюкоза в плазме',
            en: 'Glucose in plasma',
          ),
          specimen: 'plasma',
          specimenNames: ['plasma', 'плазма'],
          unitIds: ['unit.mmol-per-l', 'unit.mg-per-dl'],
        ),
        IndicatorConcept(
          id: 'indicator.glucose.urine',
          label: const TerminologyLabel(
            ru: 'Глюкоза в моче',
            en: 'Glucose in urine',
          ),
          specimen: 'urine',
          specimenNames: ['urine', 'моча'],
          unitIds: ['unit.mmol-per-l', 'unit.mg-per-dl'],
        ),
        IndicatorConcept(
          id: 'indicator.hemoglobin.blood',
          label: const TerminologyLabel(
            ru: 'Гемоглобин в крови',
            en: 'Hemoglobin in blood',
          ),
          specimen: 'whole-blood',
          specimenNames: ['blood', 'whole blood', 'кровь', 'цельная кровь'],
          unitIds: ['unit.g-per-l'],
        ),
        IndicatorConcept(
          id: 'indicator.creatinine.serum',
          label: const TerminologyLabel(
            ru: 'Креатинин в сыворотке',
            en: 'Creatinine in serum',
          ),
          specimen: 'serum',
          specimenNames: ['serum', 'сыворотка'],
          unitIds: ['unit.umol-per-l', 'unit.mg-per-dl'],
        ),
      ],
      units: const [
        UnitConcept(
          id: 'unit.mmol-per-l',
          label: TerminologyLabel(
            ru: 'Миллимоль на литр',
            en: 'Millimole per litre',
          ),
          symbol: 'mmol/L',
          dimension: 'amount-concentration',
        ),
        UnitConcept(
          id: 'unit.umol-per-l',
          label: TerminologyLabel(
            ru: 'Микромоль на литр',
            en: 'Micromole per litre',
          ),
          symbol: 'µmol/L',
          dimension: 'amount-concentration',
        ),
        UnitConcept(
          id: 'unit.mg-per-dl',
          label: TerminologyLabel(
            ru: 'Миллиграмм на децилитр',
            en: 'Milligram per decilitre',
          ),
          symbol: 'mg/dL',
          dimension: 'mass-concentration',
        ),
        UnitConcept(
          id: 'unit.g-per-l',
          label: TerminologyLabel(ru: 'Грамм на литр', en: 'Gram per litre'),
          symbol: 'g/L',
          dimension: 'mass-concentration',
        ),
      ],
      indicatorAliases: const [
        TermAlias(
          id: 'glucose.plasma.ru',
          text: 'Глюкоза в плазме',
          conceptId: 'indicator.glucose.plasma',
        ),
        TermAlias(
          id: 'glucose.plasma.en',
          text: 'Glucose in plasma',
          conceptId: 'indicator.glucose.plasma',
        ),
        TermAlias(
          id: 'glucose.plasma.short.ru',
          text: 'Глюкоза',
          conceptId: 'indicator.glucose.plasma',
        ),
        TermAlias(
          id: 'glucose.plasma.short.en',
          text: 'Glucose',
          conceptId: 'indicator.glucose.plasma',
        ),
        TermAlias(
          id: 'glucose.urine.ru',
          text: 'Глюкоза в моче',
          conceptId: 'indicator.glucose.urine',
        ),
        TermAlias(
          id: 'glucose.urine.en',
          text: 'Glucose in urine',
          conceptId: 'indicator.glucose.urine',
        ),
        TermAlias(
          id: 'glucose.urine.short.ru',
          text: 'Глюкоза',
          conceptId: 'indicator.glucose.urine',
        ),
        TermAlias(
          id: 'glucose.urine.short.en',
          text: 'Glucose',
          conceptId: 'indicator.glucose.urine',
        ),
        TermAlias(
          id: 'hemoglobin.ru',
          text: 'Гемоглобин в крови',
          conceptId: 'indicator.hemoglobin.blood',
        ),
        TermAlias(
          id: 'hemoglobin.en',
          text: 'Hemoglobin in blood',
          conceptId: 'indicator.hemoglobin.blood',
        ),
        TermAlias(
          id: 'hemoglobin.short.ru',
          text: 'Гемоглобин',
          conceptId: 'indicator.hemoglobin.blood',
        ),
        TermAlias(
          id: 'hemoglobin.short.en',
          text: 'Hemoglobin',
          conceptId: 'indicator.hemoglobin.blood',
        ),
        TermAlias(
          id: 'hemoglobin.hgb',
          text: 'HGB',
          conceptId: 'indicator.hemoglobin.blood',
        ),
        TermAlias(
          id: 'creatinine.ru',
          text: 'Креатинин в сыворотке',
          conceptId: 'indicator.creatinine.serum',
        ),
        TermAlias(
          id: 'creatinine.en',
          text: 'Creatinine in serum',
          conceptId: 'indicator.creatinine.serum',
        ),
        TermAlias(
          id: 'creatinine.short.ru',
          text: 'Креатинин',
          conceptId: 'indicator.creatinine.serum',
        ),
        TermAlias(
          id: 'creatinine.short.en',
          text: 'Creatinine',
          conceptId: 'indicator.creatinine.serum',
        ),
      ],
      unitAliases: const [
        TermAlias(id: 'mmol.ru', text: 'ммоль/л', conceptId: 'unit.mmol-per-l'),
        TermAlias(id: 'mmol.en', text: 'mmol/L', conceptId: 'unit.mmol-per-l'),
        TermAlias(
          id: 'umol.ru',
          text: 'мкмоль/л',
          conceptId: 'unit.umol-per-l',
        ),
        TermAlias(id: 'umol.en', text: 'µmol/L', conceptId: 'unit.umol-per-l'),
        TermAlias(
          id: 'umol.ascii',
          text: 'umol/L',
          conceptId: 'unit.umol-per-l',
        ),
        TermAlias(
          id: 'umol.greek',
          text: 'μmol/L',
          conceptId: 'unit.umol-per-l',
        ),
        TermAlias(id: 'mgdl.ru', text: 'мг/дл', conceptId: 'unit.mg-per-dl'),
        TermAlias(id: 'mgdl.en', text: 'mg/dL', conceptId: 'unit.mg-per-dl'),
        TermAlias(id: 'gl.ru', text: 'г/л', conceptId: 'unit.g-per-l'),
        TermAlias(id: 'gl.en', text: 'g/L', conceptId: 'unit.g-per-l'),
      ],
    ),
  ],
);
