import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:design_system/design_system.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/history/history.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../app_test.dart' as navigation;

HistoryData data() => HistoryData(
  rows: [
    for (var i = 0; i < 30; i++)
      HistoryRow(
        id: '$i',
        name: 'Synthetic marker $i',
        group: 'Synthetic group',
        points: [
          for (var month = 1; month < 12; month++)
            HistoryPoint(
              date: CalendarDate(2026, month, 1),
              value: '$i,00',
              unit: 'original unit',
            ),
        ],
      ),
  ],
  events: [
    HistoryEvent(
      id: 'med',
      name: 'Synthetic medicine',
      start: CalendarDate(2025, 1, 1),
      kind: HistoryEventKind.medication,
    ),
  ],
);
Widget app(
  HistoryViewModel model,
  String language, {
  VoidCallback? export,
  ValueChanged<HistoryRow>? onOpen,
}) => MaterialApp(
  locale: Locale(language),
  theme: language == 'ru' ? AppTheme.light : AppTheme.dark,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AnalysisHistoryView(
      model: model,
      onExport: export,
      onOpenRow: onOpen,
    ),
  ),
);

void main() {
  testWidgets('direct history link returns to summary', (tester) async {
    await navigation.launch(tester, initialLocation: '/history');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('system-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['ru', 'en']) {
    testWidgets(
      'selection survives collapsed search, rotation, keyboard and resize $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final m = HistoryViewModel(data(), today: CalendarDate(2026, 11, 27));
        addTearDown(m.dispose);
        await tester.pumpWidget(app(m, language));
        await tester.pumpAndSettle();
        final name = find.byKey(const ValueKey('history-row-0'));
        final left = tester.getTopLeft(name).dx;
        await tester.drag(
          find.byKey(const Key('history-horizontal')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(name).dx, left);
        await tester.tap(find.byKey(const Key('history-search-toggle')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('history-search')),
          'Synthetic marker 0',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('history-select-0')));
        await tester.pumpAndSettle();
        tester.testTextInput.hide();
        await tester.tap(find.byKey(const Key('history-search-toggle')));
        await tester.pumpAndSettle();
        expect(m.selected, {'0'});
        expect(find.byKey(const ValueKey('history-row-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('history-row-1')), findsNothing);
        await tester.tap(find.byKey(const Key('history-events-toggle')));
        await tester.pumpAndSettle();
        expect(find.text('Synthetic medicine'), findsOneWidget);
        await tester.tap(find.byKey(const Key('history-rotate')));
        await tester.pumpAndSettle();
        expect(m.selected, {'0'});
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpAndSettle();
        expect(m.selected, {'0'});
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('history-search-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(InputChip),
            matching: find.text('Synthetic marker 0'),
          ),
        );
        await tester.pumpAndSettle();
        if (m.selected.isNotEmpty) {
          await tester.tap(
            find
                .descendant(
                  of: find.byType(InputChip),
                  matching: find.byType(Icon),
                )
                .last,
          );
          await tester.pumpAndSettle();
        }
        expect(m.selected, isEmpty);
      },
    );
    for (final size in [const Size(320, 640), const Size(844, 390)]) {
      testWidgets('history controls fit 200% text and events $language $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final m = HistoryViewModel(data(), today: CalendarDate(2026, 11, 27))
          ..toggleEvents();
        addTearDown(m.dispose);
        await tester.pumpWidget(app(m, language, export: () {}));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('history-period')));
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text(language == 'ru' ? 'Две последние' : 'Latest two visits')
              .last,
        );
        await tester.pumpAndSettle();
        expect(m.dates, hasLength(2));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
