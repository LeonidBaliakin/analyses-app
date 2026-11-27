import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/history/history.dart';
import 'package:health_app/l10n/generated/app_localizations_en.dart';
import 'package:medical_domain/medical_domain.dart';

HistoryData fixture() => HistoryData(
  rows: [
    HistoryRow(
      id: 'one',
      name: 'SYNTHETIC <marker>',
      group: 'Synthetic',
      points: [
        HistoryPoint(
          date: CalendarDate(2026, 9, 1),
          value: '< 0,0100',
          unit: 'source unit',
          source: 'Source A',
          reference: '< 0,02',
        ),
        HistoryPoint(
          date: CalendarDate(2026, 11, 1),
          value: '7,00',
          source: 'Source A',
        ),
        HistoryPoint(
          date: CalendarDate(2026, 11, 1),
          value: '8,00',
          source: 'Source A',
        ),
      ],
    ),
    HistoryRow(
      id: 'two',
      name: 'SYNTHETIC different method',
      group: 'Synthetic',
      points: [
        HistoryPoint(
          date: CalendarDate(2026, 10, 1),
          value: '9,000',
          source: 'Source B',
        ),
      ],
    ),
  ],
  events: [
    HistoryEvent(
      id: 'med',
      name: 'Synthetic continuing medicine',
      start: CalendarDate(2025, 1, 1),
      kind: HistoryEventKind.medication,
    ),
    HistoryEvent(
      id: 'ended',
      name: 'Synthetic past medicine',
      start: CalendarDate(2025, 1, 1),
      end: CalendarDate(2025, 1, 10),
      kind: HistoryEventKind.medication,
    ),
    HistoryEvent(
      id: 'measurement',
      name: 'Synthetic old measurement',
      start: CalendarDate(2026, 9, 1),
      kind: HistoryEventKind.measurement,
    ),
  ],
);

void main() {
  test('periods use visit dates, keep repeated results and include preexisting courses', () {
    final m = HistoryViewModel(fixture(), today: CalendarDate(2026, 11, 27));
    addTearDown(m.dispose);
    m.selectPeriod(HistoryPeriod.recent);
    expect(m.dates, [CalendarDate(2026, 10, 1), CalendarDate(2026, 11, 1)]);
    expect(
      m.points(m.rows.first, CalendarDate(2026, 11, 1)).map((p) => p.value),
      ['7,00', '8,00'],
    );
    expect(m.events.map((e) => e.id), ['med']);
    m.selectPeriod(HistoryPeriod.latest);
    expect(m.rows.map((r) => r.id), ['one']);
    m.setPeriod('2026-11-10', '2026-11-01');
    expect(m.invalidPeriod, isTrue);
    m.setPeriod('2026-08-01', '2026-09-30');
    expect(m.invalidPeriod, isFalse);
    expect(m.rows.single.id, 'one');
  });

  test(
    'search selection and printed report share raw values, scope and escaping',
    () {
      final m = HistoryViewModel(fixture(), today: CalendarDate(2026, 11, 27));
      addTearDown(m.dispose);
      m.setQuery('different method');
      expect(m.suggestions.single.id, 'two');
      m.select('one');
      final html = historyDocument(
        m,
        AppLocalizationsEn(),
        profile: '<script>synthetic</script>',
      );
      expect(html, contains('&lt; 0,0100'));
      expect(html, contains('7,00'));
      expect(html, contains('8,00'));
      expect(html, contains('source unit'));
      expect(html, contains('&lt;script&gt;synthetic&lt;&#47;script&gt;'));
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('9,000')));
      expect(html, isNot(contains('Synthetic continuing medicine')));
      m.toggleEvents();
      expect(
        historyDocument(m, AppLocalizationsEn()),
        contains('Synthetic continuing medicine'),
      );
      m.updateData(fixture());
      expect(m.selected, {'one'});
      m.updateData(HistoryData(rows: [fixture().rows.last]));
      expect(m.rows, isEmpty);
      expect(m.selected, {'one'});
      m.updateData(fixture());
      m.reset();
      expect(m.rows, hasLength(2));
      expect(m.query, isEmpty);
    },
  );
}
