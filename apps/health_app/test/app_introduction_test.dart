import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app/app/health_app.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/presentation/demo_catalog.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show launch;
import 'support/memory_preferences_repository.dart';

const introduction = Key('app-introduction');
const next = Key('introduction-next');
const back = Key('introduction-back');
const skip = Key('introduction-skip');

String route(WidgetTester tester) =>
    (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter)
        .routeInformationProvider
        .value
        .uri
        .path;

Future<void> press(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> restore(
  WidgetTester tester,
  MemoryPreferencesRepository repository, {
  DeviceAccessViewModel? deviceAccess,
}) async {
  await tester.pumpWidget(const SizedBox());
  final settings = SettingsViewModel(repository: repository);
  await settings.load();
  final catalog = await tester.runAsync(DemoCatalog.load);
  await tester.pumpWidget(
    HealthApp(
      settings: settings,
      catalog: catalog!,
      deviceAccess: deviceAccess,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tour actions return to the same step without completing the tour',
    (tester) async {
      await launch(tester, introductionCompleted: false);
      await press(tester, const Key('introduction-try'));
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 6'), findsOneWidget);
      await press(tester, next);
      await press(tester, const Key('introduction-try'));
      expect(find.text('File or PDF'), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 6'), findsOneWidget);
    },
  );
  testWidgets('first launch opens the six step app introduction', (
    tester,
  ) async {
    await launch(
      tester,
      language: AppLanguage.ru,
      introductionCompleted: false,
    );
    expect(find.text('Шаг 1 из 6'), findsOneWidget);
    expect(find.text('Заполните профиль'), findsOneWidget);
  });

  testWidgets('settings restart opens the app introduction', (tester) async {
    await launch(
      tester,
      language: AppLanguage.ru,
      initialLocation: '/settings',
    );
    final restart = find.text('Пройти первые шаги заново');
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1 из 6'), findsOneWidget);
    expect(find.text('Заполните профиль'), findsOneWidget);
  });

  testWidgets(
    'tour navigates all steps, returns to settings and retains input',
    (tester) async {
      final storage = MemoryPreferencesRepository();
      await launch(tester, repository: storage, initialLocation: '/settings');
      final support = find.byType(TextField).last;
      await tester.ensureVisible(support);
      await tester.enterText(support, 'Keep this draft');
      final restart = find.text('Start the introduction again');
      await tester.ensureVisible(restart);
      await tester.tap(restart);
      await tester.pumpAndSettle();
      expect(route(tester), '/profile');
      await press(tester, next);
      expect(route(tester), '/results');
      await press(tester, back);
      expect(route(tester), '/profile');
      for (final (index, path) in [
        '/results',
        '/',
        '/labs',
        '/doctors',
        '/sharing',
      ].indexed) {
        await press(tester, next);
        expect(route(tester), path);
        expect(find.text('Step ${index + 2} of 6'), findsOneWidget);
      }
      await press(tester, next);
      expect(find.byKey(introduction), findsNothing);
      expect(route(tester), '/results');
      expect(find.text('File or PDF'), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      final router =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as GoRouter;
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final complete in [true, false]) {
    testWidgets(
      '${complete ? 'completion' : 'skip'} persists across restart and appearance changes',
      (tester) async {
        final storage = MemoryPreferencesRepository();
        final settings = await launch(
          tester,
          repository: storage,
          introductionCompleted: false,
        );
        if (complete) {
          for (var i = 0; i < 5; i++) {
            await press(tester, next);
          }
          await press(tester, next);
        } else {
          await press(tester, skip);
        }
        expect(storage.value.introductionCompleted, isTrue);
        expect(route(tester), complete ? '/results' : '/');
        if (complete) {
          await tester.tap(find.byTooltip('Close').last);
          await tester.pumpAndSettle();
        }
        await settings.setLanguage(AppLanguage.ru);
        await settings.setThemeMode(AppThemeMode.dark);
        await restore(tester, storage);
        expect(find.byKey(introduction), findsNothing);
        expect(storage.value.introductionCompleted, isTrue);
        expect(storage.value.language, AppLanguage.ru);
        expect(storage.value.themeMode, AppThemeMode.dark);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed completion keeps the step open and allows retry', (
    tester,
  ) async {
    final storage = MemoryPreferencesRepository()..failWrite = true;
    await launch(tester, repository: storage, introductionCompleted: false);
    await press(tester, skip);
    expect(find.byKey(introduction), findsOneWidget);
    expect(find.textContaining('Could not save completion'), findsOneWidget);
    expect(storage.value.introductionCompleted, isFalse);
    expect(route(tester), '/profile');
    storage.failWrite = false;
    await press(tester, skip);
    expect(find.byKey(introduction), findsNothing);
    expect(storage.value.introductionCompleted, isTrue);
    expect(storage.writes, 2);
    await restore(tester, storage);
    expect(find.byKey(introduction), findsNothing);
  });

  testWidgets('device access closes before the app tour opens', (tester) async {
    final access = DeviceAccessViewModel(
      gateway: const UnavailableDeviceAccess(),
      introductionRequired: true,
    );
    await restore(tester, MemoryPreferencesRepository(), deviceAccess: access);
    expect(find.byKey(const Key('access-continue')), findsOneWidget);
    expect(find.byKey(introduction), findsNothing);
    await press(tester, const Key('access-continue'));
    expect(find.byKey(const Key('access-continue')), findsNothing);
    expect(find.byKey(introduction), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back skips and remembers the tour', (tester) async {
    final storage = MemoryPreferencesRepository();
    await launch(tester, repository: storage, introductionCompleted: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(introduction), findsNothing);
    expect(storage.value.introductionCompleted, isTrue);
    expect(route(tester), '/');
  });

  for (final language in [AppLanguage.ru, AppLanguage.en]) {
    testWidgets(
      '${language.name} tour retains step across rotation and folding with large text',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await launch(
          tester,
          language: language,
          themeMode: AppThemeMode.dark,
          introductionCompleted: false,
        );
        await press(tester, next);
        for (final size in [
          const Size(812, 375),
          const Size(1200, 800),
          const Size(900, 840),
        ]) {
          tester.view.physicalSize = size;
          tester.view.displayFeatures = size.width == 900
              ? [
                  const DisplayFeature(
                    bounds: Rect.fromLTWH(440, 0, 20, 840),
                    type: DisplayFeatureType.hinge,
                    state: DisplayFeatureState.postureHalfOpened,
                  ),
                ]
              : [];
          await tester.pumpAndSettle();
          expect(
            find.text(
              language == AppLanguage.ru ? 'Шаг 2 из 6' : 'Step 2 of 6',
            ),
            findsOneWidget,
          );
          expect(route(tester), '/results');
          expect(tester.takeException(), isNull);
        }
        await press(tester, skip);
        expect(find.byKey(introduction), findsNothing);
      },
    );
  }
}
