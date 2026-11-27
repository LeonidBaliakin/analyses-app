import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:health_app/features/records/records.dart';
import 'package:health_app/features/reports/reports.dart';
import 'package:health_app/features/sync/sync.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';

import 'support/memory_records_repository.dart';

class ConflictStore implements SyncStore {
  late SyncConflict conflict;
  bool? chosen;
  int? chosenRevision;
  @override
  Future<SyncScope?> syncScope(String p) async => null;
  @override
  Future<int> pendingSyncCount(String p) async => 1;
  @override
  Future<List<SyncConflict>> syncConflicts(String p) async =>
      chosen == null ? [conflict] : [];
  @override
  Future<void> resolveSyncConflict(
    String p,
    String id, {
    required bool keepLocal,
    required String operationId,
    required int localRevision,
    required int remoteVersion,
  }) async {
    chosen = keepLocal;
    chosenRevision = localRevision;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  Widget app(Widget home, String language, bool dark) => MaterialApp(
    locale: Locale(language),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: home,
  );
  for (final (language, dark) in [('ru', false), ('en', true)]) {
    testWidgets(
      'period preview/export and fold preserve entered dates $language',
      (tester) async {
        final repo = MemoryRecordsRepository();
        repo.entries['local-profile'] = const RecordEntry(
          MedicalProfile(
            id: 'local-profile',
            name: 'SYNTHETIC <script>alert(1)</script>',
          ),
          1,
        );
        repo.entries['r'] = RecordEntry(
          LabResult(
            id: 'r',
            profileId: 'local-profile',
            name: 'Synthetic marker',
            date: CalendarDate(2026, 11, 1),
            value: const SourceValue('< 0,0100', ResultValueKind.comparison),
            category: AnalysisCategory.blood,
            unit: 'unknown',
          ),
          1,
        );
        final records = RecordsViewModel(
          repository: repo,
          newId: () => '',
          clock: () => DateTime(2026, 11, 25),
        );
        await records.load();
        String? exported;
        final model = ReportsViewModel(
          records: records,
          clock: () => DateTime(2026, 11, 25),
          export: (name, html) async {
            exported = html;
            return true;
          },
        );
        addTearDown(model.dispose);
        addTearDown(records.dispose);
        tester.view.physicalSize = const Size(1100, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget home() => MediaQuery(
          data: MediaQueryData(
            size: Size(tester.view.physicalSize.width, 900),
            displayFeatures: const [
              DisplayFeature(
                bounds: Rect.fromLTWH(500, 0, 30, 900),
                type: DisplayFeatureType.hinge,
                state: DisplayFeatureState.postureHalfOpened,
              ),
            ],
          ),
          child: ReportsPage(model: model),
        );
        await tester.pumpWidget(app(Scaffold(body: home()), language, dark));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('history-period')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(language == 'ru' ? 'Выбрать даты' : 'Choose dates').last,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('report-to')),
          '2026-11-25',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('report-from')),
          '2026-11-20',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Synthetic marker'), findsNothing);
        tester.view.physicalSize = const Size(700, 1000);
        await tester.pumpWidget(app(Scaffold(body: home()), language, dark));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('report-from')))
              .controller!
              .text,
          '2026-11-20',
        );
        await tester.enterText(
          find.byKey(const Key('report-from')),
          '2026-11-01',
        );
        await tester.pumpAndSettle();
        final button = find.byKey(const Key('history-export'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(language == 'ru' ? 'Сохранить PDF' : 'Save PDF'),
        );
        await tester.pumpAndSettle();
        expect(exported, contains('&lt; 0,0100'));
        expect(exported, contains('unknown'));
        expect(exported, contains('&lt;script&gt;'));
        expect(exported, isNot(contains('<script>')));
        await tester.enterText(
          find.byKey(const Key('report-to')),
          '2026-10-01',
        );
        await tester.pumpAndSettle();
        expect(tester.widget<PopupMenuButton<int>>(button).enabled, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('conflict exposes both values and explicit choice $language', (
      tester,
    ) async {
      final store = ConflictStore();
      LabResult r(String v) => LabResult(
        id: 'r',
        profileId: 'p',
        name: 'Synthetic',
        date: CalendarDate(2026, 11, 25),
        value: SourceValue(v, ResultValueKind.numeric),
        category: AnalysisCategory.blood,
      );
      store.conflict = SyncConflict(
        RecordEntry(r('6,00'), 3),
        RemoteRecord(
          payload: Map<String, dynamic>.from(encodeRecord(r('7,00'))),
          version: 8,
          deleted: true,
          sequence: 12,
        ),
      );
      final model = SyncViewModel(
        store: store,
        profileId: 'p',
        newId: () => 'resolve',
        clock: DateTime.now,
        gatewayFactory: (_, _) => throw StateError('must not contact network'),
        onChanged: () async {},
      );
      addTearDown(model.dispose);
      await model.refresh();
      await tester.pumpWidget(
        app(SyncPage(model: model, onClose: () {}), language, dark),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('6,00'), findsOneWidget);
      expect(find.textContaining('7,00'), findsOneWidget);
      final choose = find.byKey(const Key('use-server-r'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      expect(store.chosen, isFalse);
      expect(store.chosenRevision, 3);
      expect(find.byKey(const Key('use-server-r')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'mobile save unavailability offers explicit copy of the complete report',
    (tester) async {
      final repo = MemoryRecordsRepository();
      repo.entries['local-profile'] = const RecordEntry(
        MedicalProfile(id: 'local-profile', name: 'SYNTHETIC mobile profile'),
        1,
      );
      final records = RecordsViewModel(
        repository: repo,
        newId: () => '',
        clock: () => DateTime(2026, 11, 25),
      );
      await records.load();
      String? copied;
      final model = ReportsViewModel(
        records: records,
        clock: () => DateTime(2026, 11, 25),
        canExport: false,
        export: (_, _) => throw StateError('file save must not run'),
        copy: (text) async {
          copied = text;
        },
      );
      addTearDown(model.dispose);
      addTearDown(records.dispose);
      await tester.pumpWidget(
        app(Scaffold(body: ReportsPage(model: model)), 'en', false),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-export')), findsNothing);
      final button = find.byKey(const Key('copy-local-report'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(copied, contains('SYNTHETIC mobile profile'));
      expect(copied, contains('2026-11-25'));
      expect(copied, isNot(contains('<html')));
      expect(tester.takeException(), isNull);
    },
  );
}
