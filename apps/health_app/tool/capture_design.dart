// Explicit visual comparison utility; not part of the default test suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';
import 'package:health_app/app/health_app.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/features/history/history.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:health_app/presentation/demo_catalog.dart';

import '../test/support/memory_preferences_repository.dart';

void main() {
  for (final entry in [
    ('summary', '/'),
    ('files', '/results'),
    ('profile', '/profile'),
    ('settings', '/settings'),
    ('sharing', '/sharing'),
    ('history', '/history'),
    ('history-dark', '/history'),
    ('history-landscape', '/history'),
    ('history-events', '/history'),
    ('settings-menu', '/settings'),
    ('settings-dark-menu', '/settings'),
    ('introduction', '/'),
    ('introduction-dark', '/'),
    ('rail-dark', '/doctors'),
  ]) {
    testWidgets('capture ${entry.$1}', (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      tester.view.physicalSize = entry.$1.contains('landscape')
          ? const ui.Size(844, 390)
          : entry.$1.startsWith('rail')
          ? const ui.Size(900, 840)
          : const ui.Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final catalog = await tester.runAsync(() async {
        final font = FontLoader('packages/design_system/Manrope')
          ..addFont(
            rootBundle.load('packages/design_system/assets/fonts/Manrope.ttf'),
          );
        await font.load();
        final icons = FontLoader(
          Icons.add.fontPackage == null
              ? Icons.add.fontFamily!
              : 'packages/${Icons.add.fontPackage}/${Icons.add.fontFamily}',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        return DemoCatalog.load();
      });
      final repo = MemoryPreferencesRepository()
        ..value = AppPreferences(
          introductionCompleted: !entry.$1.startsWith('introduction'),
          language: AppLanguage.ru,
          themeMode: entry.$1.contains('dark')
              ? AppThemeMode.dark
              : AppThemeMode.light,
        );
      final settings = SettingsViewModel(repository: repo);
      await settings.load();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: HealthApp(
            settings: settings,
            catalog: catalog!,
            initialLocation: entry.$2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      if (entry.$1 == 'history') {
        final viewer = tester.widget<AnalysisHistoryView>(
          find.byType(AnalysisHistoryView),
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(AnalysisHistoryView)),
        );
        final html = historyDocument(viewer.model, l);
        await tester.runAsync(
          () =>
              File('/private/tmp/analyses-history-print.html')
                  .writeAsString(html),
        );
      }
      if (entry.$1 == 'history-events') {
        await tester.tap(find.byKey(const Key('history-events-toggle')));
        await tester.pumpAndSettle();
      }
      if (entry.$1.endsWith('menu')) {
        final field = find.byType(AppSelect<AppThemeMode>);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
      }
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/private/tmp/analyses-native-${entry.$1}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
}
