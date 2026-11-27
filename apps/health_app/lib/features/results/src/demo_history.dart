import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../presentation/demo_catalog.dart';
import '../../../presentation/reference_labels.dart';
import '../../history/history.dart';

HistoryData demoHistoryData(BuildContext context, DemoCatalog catalog) {
  CalendarDate date(String text) {
    if (text.contains('-')) return CalendarDate.parse(text);
    final parts = text.split('.').map(int.parse).toList();
    return CalendarDate(
      parts[2] < 100 ? 2000 + parts[2] : parts[2],
      parts[1],
      parts[0],
    );
  }

  return HistoryData(
    isDemo: true,
    rows: [
      for (final result in catalog.results)
        HistoryRow(
          id: result.id,
          name: result.name,
          group: systemTitle(context, result.systemId),
          points: [
            for (final point in result.points)
              HistoryPoint(
                date: date(point.date),
                value: point.raw,
                unit: result.unit == '—' ? '' : result.unit,
                reference: result.reference,
                source: catalog.labs[point.visit],
                status: point.status,
              ),
          ],
        ),
    ],
    events: [
      for (final pair in [
        ('med', HistoryEventKind.medication),
        ('ill', HistoryEventKind.illness),
        ('hosp', HistoryEventKind.illness),
        ('cmp', HistoryEventKind.complaint),
      ])
        for (final (i, raw)
            in (catalog.events[pair.$1] as List<dynamic>).indexed)
          HistoryEvent(
            id: '${pair.$1}-$i',
            name: raw['n'] as String,
            start: date(raw['f'] as String),
            end: (raw['t'] as String? ?? '').isEmpty
                ? null
                : date(raw['t'] as String),
            kind: pair.$2,
            detail: [
              raw['m'],
              raw['w'],
              raw['tmax'],
              raw['ab'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
          ),
      for (final (i, raw)
          in (catalog.events['weight'] as List<dynamic>).indexed)
        HistoryEvent(
          id: 'weight-$i',
          name: '${raw['kg']} кг',
          start: date(raw['d'] as String),
          kind: HistoryEventKind.measurement,
        ),
    ],
  );
}
