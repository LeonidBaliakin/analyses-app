import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';
import 'package:test/test.dart';

final original = OriginalDocument(
  documentId: 'd',
  originalId: 'o',
  profileId: 'p',
  fileName: 'synthetic.png',
  mime: 'image/png',
  size: 8,
  sha256: 'a' * 64,
  importedAt: DateTime.utc(2026),
  importSource: 'files',
);
final job = ProcessingJob(
  id: 'j',
  original: original,
  mode: ProcessingMode.local,
  terminologyReleaseId: bundledTerminology.active.id,
  runtimeId: 'runtime1',
);
Map<String, dynamic> wire({
  String value = '< 0,0100',
  String date = '24.11.2026',
  String unit = 'г/л',
}) => {
  'schemaVersion': 1,
  'runtimeId': 'runtime1',
  'versions': {'ocr': 'o1', 'model': 'm1', 'prompt': 'p1', 'worker': 'w1'},
  'pages': [
    {'number': 1, 'text': 'Дата: 24.11.2026\nГемоглобин < 0,0100 г/л 100-200'},
  ],
  'rows': [
    {
      'page': 1,
      'evidence': 'Гемоглобин < 0,0100 г/л 100-200',
      'name': 'Гемоглобин',
      'value': value,
      'unit': unit,
      'reference': '100-200',
      'date': date,
      'laboratory': '',
      'specimen': '',
      'method': '',
    },
  ],
};
ProcessingDraft parse(Map<String, dynamic> w) =>
    decodeGeneratedDraft(w, job, bundledTerminology.active);
void main() {
  test('grounded precision, comparison, spans and date survive; coding needs explicit choice', () {
    final d = parse(wire()), r = d.rows.single;
    expect(r.review['value'], '< 0,0100');
    expect(r.valueKind, ResultValueKind.comparison);
    expect(r.review['date'], '2026-11-24');
    expect(r.source['date']!.raw, '24.11.2026');
    expect(r.source['value']!.start, greaterThan(0));
    expect(r.coding, isNull);
    expect(encodeDraft(decodeDraft(encodeDraft(d))), encodeDraft(d));
    final result = confirmedResults(d).single;
    expect(result.value.raw, '< 0,0100');
    expect(result.documentSource!.originalSha256, original.sha256);
    expect(result.documentSource!.fields['value'], '< 0,0100');
  });
  test('hallucinated unit/date and stripped comparator or precision are not prefilled', () {
    for (final v in ['0,0100', '< 0,01', '0,01']) {
      final r = parse(wire(value: v, date: 'today', unit: 'invented'))
          .rows
          .single;
      expect(r.review['value'], '');
      expect(r.source['value']!.issue, 'unbacked');
      expect(r.review['date'], '');
      expect(r.review['unit'], '');
      expect(r.source['unit']!.raw, 'invented');
    }
  });
  test('a reference containing the same number cannot conceal a stripped comparison; mixed columns are rejected', () {
    final w = wire(value: '0,0100');
    (w['pages'] as List).single['text'] =
        'Гемоглобин < 0,0100 г/л 0,0100-0,020';
    (w['rows'] as List).single['evidence'] =
        'Гемоглобин < 0,0100 г/л 0,0100-0,020';
    (w['rows'] as List).single['reference'] = '0,0100-0,020';
    expect(parse(w).rows.single.review['value'], '');
    final mixed = parse(wire(value: '< 0,0100 г/л')).rows.single;
    expect(mixed.review['value'], '');
    expect(mixed.source['value']!.raw, '< 0,0100 г/л');
    expect(mixed.source['value']!.issue, 'mixed_value');
  });
  test(
    'unknown date remains unknown until user supplies complete valid date',
    () {
      final d = parse(wire(date: ''));
      expect(() => confirmedResults(d), throwsA(isA<ProcessingFailure>()));
      for (final input in ['2026', '11.2026', '31.02.2026']) {
        expect(completeDate(input), '');
      }
      final fixed = d.edited([
        d.rows.single.edit({...d.rows.single.review, 'date': '2026-11-25'}),
      ]);
      expect(confirmedResults(fixed).single.date, CalendarDate(2026, 11, 25));
      expect(fixed.rows.single.source['date']!.raw, '');
    },
  );
  test(
    'schema/version, invented evidence and extra tool fields are rejected',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (w) => w['runtimeId'] = 'other',
        (w) => w['schemaVersion'] = 2,
        (w) => (w['rows'] as List).single['evidence'] = 'not in document',
        (w) => (w['rows'] as List).single['command'] = 'send document',
      ]) {
        final w = wire();
        mutate(w);
        expect(() => parse(w), throwsA(isA<ProcessingFailure>()));
      }
    },
  );
  test('edited context cannot silently rebind confirmed normalization', () {
    final d = parse(wire());
    final r = d.rows.single;
    final c = LabResultCoding(
      terminologyReleaseId: d.terminologyReleaseId,
      indicatorId: 'indicator.hemoglobin.blood',
      unitId: 'unit.g_per_l',
      sourceName: r.review['name']!,
      sourceUnit: r.review['unit']!,
      sourceLaboratory: '',
      sourceSpecimen: '',
      sourceMethod: '',
    );
    final coded = d.edited([r.edit(r.review, coding: c)]);
    final changed = coded.edited([
      coded.rows.single.edit({...r.review, 'name': 'Other'}, coding: c),
    ]);
    final restored = decodeDraft(encodeDraft(changed));
    expect(restored.rows.single.coding!.sourceName, 'Гемоглобин');
    expect(() => confirmedResults(restored), throwsA(isA<InvalidRecord>()));
    expect(classifyValue('negative'), ResultValueKind.qualitative);
  });
}
