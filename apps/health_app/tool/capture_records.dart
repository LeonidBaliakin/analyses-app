// Explicit visual verification utility, not a default test-suite assertion.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:health_app/features/records/records.dart';
import 'package:medical_domain/medical_domain.dart';

import '../test/records_flow_test.dart'
    show launch, tap, enter, selectTerm, withProfile;

void main() {
  for (final dark in [false, true]) {
    testWidgets('capture local records ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const ui.Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await (FontLoader('packages/design_system/Manrope')..addFont(
              rootBundle.load(
                'packages/design_system/assets/fonts/Manrope.ttf',
              ),
            ))
            .load();
        await (FontLoader(
          Icons.add.fontPackage == null
              ? Icons.add.fontFamily!
              : 'packages/${Icons.add.fontPackage}/${Icons.add.fontFamily}',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final repo = withProfile()
        ..entries['synthetic-result'] = RecordEntry(
          LabResult(
            id: 'synthetic-result',
            profileId: RecordsViewModel.profileId,
            name: 'Синтетический показатель',
            date: CalendarDate(2026, 11, 24),
            category: AnalysisCategory.blood,
            laboratory: 'Учебная лаборатория',
            value: const SourceValue('0,0100', ResultValueKind.numeric),
            unit: 'ед./л',
          ),
          1,
        );
      final captureKey = GlobalKey();
      await launch(
        tester,
        repo,
        language: AppLanguage.ru,
        captureKey: captureKey,
        theme: dark ? AppThemeMode.dark : AppThemeMode.light,
      );
      Future<void> capture(String label) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/private/tmp/analyses-records-$label.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture(dark ? 'dark' : 'light');
      await tap(tester, find.text('Добавить вручную'));
      await capture(dark ? 'editor-dark' : 'editor-light');
      await enter(tester, 'name', 'HGB');
      await enter(tester, 'value', '0,0100');
      await enter(tester, 'unit', 'г/л');
      await selectTerm(tester, 'indicator', 'Гемоглобин в крови');
      await selectTerm(tester, 'unit', 'g/L · Грамм на литр');
      await tester.ensureVisible(find.byKey(const Key('term-indicator')));
      await tester.pumpAndSettle();
      await capture(dark ? 'terminology-dark' : 'terminology-light');
      expect(tester.takeException(), isNull);
    });
  }
}
