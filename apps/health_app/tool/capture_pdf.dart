import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/reports/history_pdf.dart';
import 'package:health_app/features/history/history.dart';
import 'package:medical_domain/medical_domain.dart';

void main() {
  testWidgets(
    'generate frozen selected Cyrillic PDF without unselected values',
    (tester) async {
      final d = CalendarDate(2026, 11, 27);
      final m = HistoryViewModel(
        HistoryData(
          isDemo: true,
          rows: [
            HistoryRow(
              id: 'a',
              name: 'Глюкоза — исходное название',
              group: 'Углеводный обмен',
              points: [
                HistoryPoint(
                  date: d,
                  value: '< 0,0100',
                  unit: 'ммоль/л',
                  reference: 'Исходный референс',
                  source: 'Синтетическая лаборатория',
                ),
              ],
            ),
            HistoryRow(
              id: 'b',
              name: 'EXCLUDED',
              group: 'Other',
              points: [
                HistoryPoint(
                  date: d,
                  value: '9999',
                  unit: 'u',
                  reference: 'r',
                  source: 's',
                ),
              ],
            ),
          ],
        ),
        today: d,
      );
      m.select('a');
      final frozen = m.printSnapshot(profile: 'Синтетический профиль');
      m.select('a');
      expect(frozen.rows.map((r) => r.id), ['a']);
      final bytes = await tester.runAsync(() => buildHistoryPdf(frozen, 'ru'));
      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
      await tester.runAsync(
        () => File(
          '/Users/pavel/Projects/analyses-app/.runtime/ui-parity-2026-11-27/history-selected.pdf',
        ).writeAsBytes(bytes),
      );
      m.dispose();
    },
  );
}
