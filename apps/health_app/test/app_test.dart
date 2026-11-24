import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/app/health_app.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/presentation/demo_catalog.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_preferences_repository.dart';

Future<SettingsViewModel> launch(
  WidgetTester tester, {
  String initialLocation = '/',
  AppLanguage language = AppLanguage.en,
  AppThemeMode themeMode = AppThemeMode.system,
  MemoryPreferencesRepository? repository,
  bool introductionCompleted = true,
}) async {
  final storage = repository ?? MemoryPreferencesRepository();
  storage.value = AppPreferences(
    language: language,
    themeMode: themeMode,
    introductionCompleted: introductionCompleted,
  );
  final settings = SettingsViewModel(repository: storage);
  await settings.load();
  final catalog = await tester.runAsync(DemoCatalog.load);
  await tester.pumpWidget(
    HealthApp(
      settings: settings,
      catalog: catalog!,
      initialLocation: initialLocation,
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

Future<void> choose<T>(WidgetTester tester, String text) async {
  final field = find.byType(AppSelect<T>);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in [AppLanguage.ru, AppLanguage.en]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'rail buttons fill equal widths ${language.name} scale=$textScale',
        (tester) async {
          tester.view.physicalSize = const Size(900, 840);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await launch(
            tester,
            initialLocation: '/doctors',
            language: language,
            themeMode: AppThemeMode.dark,
          );
          for (final width in [900.0, 1440.0]) {
            tester.view.physicalSize = Size(width, 840);
            await tester.pumpAndSettle();
            final rail = tester.getRect(
              find.byKey(const Key('desktop-navigation')),
            );
            final buttons = [
              for (var i = 0; i < 5; i++)
                tester.getRect(find.byKey(Key('nav-$i'))),
            ];
            for (final button in buttons) {
              expect(button.width, greaterThanOrEqualTo(rail.width - 24));
              expect(button.width, closeTo(buttons.first.width, .01));
              expect(button.height, 72);
            }
            final ink = tester.widget<Ink>(
              find.descendant(
                of: find.byKey(const Key('nav-4')),
                matching: find.byType(Ink),
              ),
            );
            expect((ink.decoration as BoxDecoration).gradient, isNotNull);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('theme applies in the first frame without rebuilding on save', (
    tester,
  ) async {
    final storage = MemoryPreferencesRepository()
      ..writeGate = Completer<void>();
    final model = await launch(
      tester,
      repository: storage,
      initialLocation: '/settings',
      themeMode: AppThemeMode.light,
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final pending = model.setThemeMode(AppThemeMode.dark);
    await tester.pump();
    final appWhileSaving = tester.widget<MaterialApp>(find.byType(MaterialApp));
    storage.writeGate!.complete();
    await pending;
    await tester.pump();
    expect(
      OrangePalette.of(tester.element(find.byType(SettingsPage))),
      same(OrangePalette.dark),
    );
    await tester.pumpAndSettle();
    expect(appWhileSaving, same(app));
    expect(
      OrangePalette.of(tester.element(find.byType(SettingsPage))).paper,
      OrangePalette.dark.paper,
    );
  });

  testWidgets('flat fold fills the unfolded display and retains input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await launch(tester);
    await tester.enterText(find.byKey(const Key('system-search')), 'ferritin');
    tester.view.physicalSize = const Size(900, 840);
    tester.view.displayFeatures = const [
      DisplayFeature(
        bounds: Rect.fromLTWH(450, 0, 0, 840),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
    ];
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Scaffold)).width, 900);
    expect(find.byKey(const Key('desktop-navigation')), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('system-search')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'ferritin',
    );
    tester.view.displayFeatures = const [];
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bottom-navigation')), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('system-search')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'ferritin',
    );
    expect(tester.takeException(), isNull);
  });

  for (final vertical in [true, false]) {
    testWidgets('half-open fold avoids crease, vertical=$vertical', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await launch(tester, initialLocation: '/results');
      tester.view.displayFeatures = [
        DisplayFeature(
          bounds: vertical
              ? const Rect.fromLTWH(450, 0, 0, 840)
              : const Rect.fromLTWH(0, 420, 900, 0),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      await tester.pumpAndSettle();
      final pane = tester.getRect(find.byType(Scaffold));
      expect(vertical ? pane.width : pane.height, vertical ? 450 : 420);
      tester.view.displayFeatures = [
        DisplayFeature(
          bounds: vertical
              ? const Rect.fromLTWH(450, 0, 0, 840)
              : const Rect.fromLTWH(0, 420, 900, 0),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Scaffold)).size, const Size(900, 840));
      expect(find.text('Upload test reports'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'directory search adds a test without filtering out laboratories',
    (tester) async {
      await launch(tester, initialLocation: '/labs', language: AppLanguage.ru);
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'Витамин D');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Витамин D'));
      await tester.pumpAndSettle();
      expect(find.text('Витамин D'), findsOneWidget);
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('МедЛаб Центр'), findsOneWidget);
    },
  );

  testWidgets(
    'original navigation opens reports and preserves route on resize',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await launch(tester);
      expect(find.text('Orange of Health'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      expect(find.text('Upload test reports'), findsOneWidget);
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desktop-navigation')), findsOneWidget);
      expect(find.text('Upload test reports'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('summary search, system selection and result details work', (
    tester,
  ) async {
    await launch(
      tester,
      language: AppLanguage.ru,
      themeMode: AppThemeMode.light,
    );
    await tester.enterText(find.byKey(const Key('system-search')), 'ферритин');
    await tester.pumpAndSettle();
    expect(find.text('Клинический анализ крови'), findsNothing);
    final system = find.text('Обмен железа');
    await tester.ensureVisible(system);
    await tester.tap(system);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ферритин').last);
    await tester.pumpAndSettle();
    expect(find.text('История значений'), findsOneWidget);
    expect(find.text('283 мкг/л'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings persist language and theme across app recreation', (
    tester,
  ) async {
    final storage = MemoryPreferencesRepository();
    await launch(tester, repository: storage, initialLocation: '/settings');
    await choose<AppLanguage>(tester, 'Русский');
    await choose<AppThemeMode>(tester, 'Тёмная');
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    await tester.pumpWidget(const SizedBox());
    final settings = SettingsViewModel(repository: storage);
    await settings.load();
    final catalog = await tester.runAsync(DemoCatalog.load);
    await tester.pumpWidget(
      HealthApp(
        settings: settings,
        catalog: catalog!,
        initialLocation: '/settings',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
  });
  testWidgets('failed settings save resets the control and allows retry', (
    tester,
  ) async {
    final storage = MemoryPreferencesRepository()..failWrite = true;
    await launch(tester, repository: storage, initialLocation: '/settings');
    await choose<AppThemeMode>(tester, 'Dark');
    expect(
      find.text('Could not save your choice. Please select the value again.'),
      findsOneWidget,
    );
    final field = tester.widget<AppSelect<AppThemeMode>>(
      find.byType(AppSelect<AppThemeMode>),
    );
    expect(field.value, AppThemeMode.system);
    storage.failWrite = false;
    await choose<AppThemeMode>(tester, 'Dark');
    expect(storage.value.themeMode, AppThemeMode.dark);
  });
  testWidgets('system locale and theme follow the device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale('de'),
      Locale('ru'),
    ];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final model = await launch(tester, language: AppLanguage.system);
    expect(find.text('Последняя сдача'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(find.text('Latest tests'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Latest tests'))).brightness,
      Brightness.dark,
    );
    await model.setThemeMode(AppThemeMode.light);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Latest tests'))).brightness,
      Brightness.light,
    );
  });
  testWidgets(
    'add action shows the original choices with an explicit preview state',
    (tester) async {
      await launch(tester);
      await tester.tap(
        find.byKey(const Key('add-analysis')).evaluate().isEmpty
            ? find.byKey(const Key('nav-2'))
            : find.byKey(const Key('add-analysis')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Photograph a report'), findsOneWidget);
      expect(find.text('File or PDF'), findsOneWidget);
      await tester.tap(find.text('Photograph a report'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This is an interface preview. Sign-in, medical record storage and external services are not connected yet.',
        ),
        findsWidgets,
      );
    },
  );
  testWidgets('all public routes and legacy documents route open', (
    tester,
  ) async {
    for (final path in [
      '/results',
      '/documents',
      '/labs',
      '/doctors',
      '/profile',
      '/sharing',
      '/settings',
      '/unknown',
    ]) {
      await launch(tester, initialLocation: path);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  for (final language in [AppLanguage.en, AppLanguage.ru]) {
    for (final mode in [AppThemeMode.light, AppThemeMode.dark]) {
      for (final size in [
        const Size(320, 640),
        const Size(844, 390),
        const Size(768, 1024),
        const Size(1440, 900),
      ]) {
        testWidgets(
          'reference layout ${language.name} ${mode.name} $size at 200%',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            addTearDown(
              tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
            await launch(tester, language: language, themeMode: mode);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const Key('nav-1')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(
              find.byTooltip(
                language == AppLanguage.ru ? 'Настройки' : 'Settings',
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets('hinge keeps selected reports outside the occluded region', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await launch(tester, initialLocation: '/results');
    tester.view.displayFeatures = const [
      DisplayFeature(
        bounds: Rect.fromLTWH(590, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
    ];
    await tester.pumpAndSettle();
    expect(find.text('Upload test reports'), findsOneWidget);
    expect(tester.getRect(find.byType(Scaffold)).right, lessThanOrEqualTo(590));
    tester.view.displayFeatures = const [];
    await tester.pumpAndSettle();
    expect(find.text('Upload test reports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
