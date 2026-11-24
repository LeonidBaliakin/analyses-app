import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'dart:io';

import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:health_app/app/health_app.dart';
import 'package:health_app/features/records/records.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/presentation/demo_catalog.dart';
import 'package:medical_domain/medical_domain.dart';

import 'support/memory_preferences_repository.dart';
import 'support/memory_records_repository.dart';

Future<RecordsViewModel> launch(
  WidgetTester tester,
  HealthRecordsRepository repository, {
  String route = '/results',
  AppLanguage language = AppLanguage.en,
  AppThemeMode theme = AppThemeMode.light,
  GlobalKey? captureKey,
}) async {
  var sequence = 0;
  final model = RecordsViewModel(
    repository: repository,
    newId: () => 'id-${sequence++}',
    clock: () => DateTime(2026, 11, 24),
  );
  await model.load();
  final settingsRepository = MemoryPreferencesRepository()
    ..value = AppPreferences(
      language: language,
      themeMode: theme,
      introductionCompleted: true,
    );
  final settings = SettingsViewModel(repository: settingsRepository);
  await settings.load();
  final catalog = await tester.runAsync(DemoCatalog.load);
  final app = HealthApp(
    settings: settings,
    catalog: catalog!,
    records: model,
    initialLocation: route,
  );
  await tester.pumpWidget(
    captureKey == null ? app : RepaintBoundary(key: captureKey, child: app),
  );
  await tester.pumpAndSettle();
  return model;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String field, String value) async {
  final finder = find.byKey(Key('record-$field'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

MemoryRecordsRepository withProfile() => MemoryRecordsRepository()
  ..entries[RecordsViewModel.profileId] = const RecordEntry(
    MedicalProfile(id: RecordsViewModel.profileId, name: 'Synthetic person'),
    1,
  );

void main() {
  testWidgets('real SQLite flow: correction history, restart and deletion', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'analyses-ui-sqlite-',
    );
    final file = File('${directory.path}/records.sqlite');
    var db = RecordsDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      directory.deleteSync(recursive: true);
    });
    await tester.runAsync(
      () => db.commit(
        const RecordMutation(
          operationId: 'seed-profile',
          record: MedicalProfile(
            id: RecordsViewModel.profileId,
            name: 'Synthetic person',
          ),
          expectedRevision: 0,
        ),
      ),
    );
    await launch(tester, db);
    await tap(tester, find.text('Add manually'));
    await enter(tester, 'name', 'Synthetic durable assay');
    await enter(tester, 'value', '1,00');
    await tap(tester, find.byKey(const Key('record-save')));
    await tap(tester, find.text('Synthetic durable assay'));
    await tap(tester, find.text('Edit'));
    await enter(tester, 'value', '2,00');
    await tap(tester, find.byKey(const Key('record-save')));
    final before = await tester.runAsync(
      () => db.read(RecordsViewModel.profileId),
    );
    final result = before!.singleWhere((e) => e.record is LabResult);
    expect(result.revision, 2);
    final history = await tester.runAsync(
      () => db.history(RecordsViewModel.profileId, result.record.id),
    );
    expect((history!.last.record as LabResult).value.raw, '1,00');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
    db = RecordsDatabase(NativeDatabase(file));
    await launch(tester, db);
    expect(find.text('Synthetic durable assay'), findsOneWidget);
    await tap(tester, find.text('Synthetic durable assay'));
    await tap(tester, find.text('Edit'));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('record-value')))
          .controller!
          .text,
      '2,00',
    );
    await tap(tester, find.text('Delete'));
    await tap(tester, find.widgetWithText(TextButton, 'Delete').last);
    expect(find.text('Synthetic durable assay'), findsNothing);
    final deleted = await tester.runAsync(
      () => db.history(RecordsViewModel.profileId, result.record.id),
    );
    expect(deleted, hasLength(3));
    expect(deleted!.first.deleted, isTrue);
  });
  testWidgets(
    'create profile, manually add a result, search and open details',
    (tester) async {
      final repository = MemoryRecordsRepository();
      await launch(tester, repository);
      expect(find.text('Ferritin'), findsNothing);
      await tap(tester, find.byKey(const Key('create-profile')));
      await enter(tester, 'name', 'Synthetic person');
      await enter(tester, 'birthDate', '1990-02-31');
      await tap(tester, find.byKey(const Key('record-save')));
      expect(find.text('Enter a valid date as YYYY-MM-DD'), findsOneWidget);
      await enter(tester, 'birthDate', '1990-02-28');
      await tap(tester, find.byKey(const Key('record-save')));
      expect(find.text('Synthetic person'), findsOneWidget);
      await tap(tester, find.text('Add manually'));
      await enter(tester, 'name', 'Synthetic assay');
      await enter(tester, 'value', '0,0100');
      await enter(tester, 'unit', 'test-unit');
      await enter(tester, 'reference', '0,001–0,020');
      await enter(tester, 'laboratory', 'Synthetic lab');
      await tap(tester, find.byKey(const Key('record-save')));
      expect(
        repository.entries.values
            .map((e) => e.record)
            .whereType<LabResult>()
            .single
            .value
            .raw,
        '0,0100',
      );
      await tester.enterText(
        find.byKey(const Key('local-result-search')),
        'Synthetic lab',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Synthetic assay'));
      expect(find.text('Original reference: 0,001–0,020'), findsOneWidget);
      expect(find.text('Laboratory: Synthetic lab'), findsOneWidget);
      expect(find.text('Manually entered and confirmed'), findsOneWidget);
    },
  );
  testWidgets('failed save retains input and retry uses the same command id', (
    tester,
  ) async {
    final repository = withProfile()..failWrite = true;
    await launch(tester, repository);
    await tap(tester, find.text('Add manually'));
    await enter(tester, 'name', 'Synthetic assay');
    await enter(tester, 'value', '5,200');
    await tap(tester, find.byKey(const Key('record-save')));
    expect(find.textContaining('Could not save.'), findsWidgets);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('record-value')))
          .controller!
          .text,
      '5,200',
    );
    repository.failWrite = false;
    await tap(tester, find.byKey(const Key('record-save')));
    expect(repository.mutations, hasLength(1));
    expect(find.text('Synthetic assay'), findsOneWidget);
  });
  testWidgets(
    'RU dark form retains input across rotation, hinge and large text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = withProfile();
      await launch(
        tester,
        repository,
        language: AppLanguage.ru,
        theme: AppThemeMode.dark,
      );
      await tap(tester, find.text('Добавить вручную'));
      await enter(tester, 'name', 'Синтетический показатель');
      await enter(tester, 'value', '1,00');
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.displayFeatures = const [
        DisplayFeature(
          bounds: Rect.fromLTWH(490, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('record-name')))
            .controller!
            .text,
        'Синтетический показатель',
      );
      tester.view.displayFeatures = const [];
      tester.view.physicalSize = const Size(844, 390);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const Key('record-save')));
      expect(repository.mutations, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'course rejects inverted dates; measurement retains source and explicit time',
    (tester) async {
      final repository = withProfile();
      await launch(tester, repository, route: '/profile');
      await tap(tester, find.text('Add course'));
      await enter(tester, 'name', 'Synthetic course');
      await enter(tester, 'start', '2026-01-20');
      await enter(tester, 'end', '2026-01-19');
      await tap(tester, find.byKey(const Key('record-save')));
      expect(find.text('End date is before start date'), findsOneWidget);
      await enter(tester, 'end', '2026-12-01');
      await tap(tester, find.byKey(const Key('record-save')));
      expect(find.text('Synthetic course'), findsOneWidget);
      await tap(tester, find.text('Add measurement'));
      await enter(tester, 'name', 'Synthetic glucose');
      await enter(tester, 'value', '5,10');
      await enter(tester, 'time', '08:15');
      await enter(tester, 'offset', '+03:00');
      await enter(tester, 'source', 'Synthetic meter');
      await tap(tester, find.byKey(const Key('record-save')));
      final measurement = repository.entries.values
          .map((e) => e.record)
          .whereType<HomeMeasurement>()
          .single;
      expect(measurement.minuteOfDay, 495);
      expect(measurement.utcOffsetMinutes, 180);
      expect(measurement.source, 'Synthetic meter');
      expect(measurement.value.raw, '5,10');
    },
  );
}
