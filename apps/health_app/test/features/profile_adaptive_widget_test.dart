import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../records_flow_test.dart' show launch, tap;
import '../support/memory_records_repository.dart';

void main() {
  testWidgets(
    'typed profile draft survives folding at 200 percent and saves one revision',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = MemoryRecordsRepository();
      repo.entries['local-profile'] = RecordEntry(
        MedicalProfile(
          id: 'local-profile',
          name: 'Synthetic',
          history: 'Original history',
          details: ProfileDetails(
            fields: {
              ProfileField.smoking: 'former',
              ProfileField.smokingQuitPrecision: 'year',
              ProfileField.smokingQuitYear: '2020',
            },
          ),
        ),
        1,
      );
      await launch(tester, repo, route: '/profile', language: AppLanguage.ru);
      await tap(tester, find.text('Основное'));
      await tester.enterText(
        find.byKey(const ValueKey(ProfileField.height)),
        '181,0',
      );
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 840);
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(440, 0, 20, 840),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      await tester.pumpAndSettle();
      tester.view.displayFeatures = [];
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(find.text('181,0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const Key('profile-save')));
      expect(repo.mutations, hasLength(1));
      final profile = repo.entries['local-profile']!.record as MedicalProfile;
      expect(profile.details![ProfileField.height], '181,0');
      expect(profile.history, 'Original history');
      for (final title in [
        'Препараты и БАДы',
        'Болезни',
        'Анамнез',
        'Образ жизни',
      ]) {
        await tap(tester, find.text(title));
        expect(tester.takeException(), isNull);
        await tap(tester, find.byTooltip('Закрыть').last);
      }
    },
  );
  testWidgets(
    'calendar cancel preserves draft; chosen birthday saves only on confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MemoryRecordsRepository();
      repo.entries['local-profile'] = RecordEntry(
        MedicalProfile(
          id: 'local-profile',
          name: 'Synthetic',
          birthDate: CalendarDate(1990, 4, 12),
        ),
        1,
      );
      await launch(tester, repo, route: '/profile', language: AppLanguage.ru);
      await tap(tester, find.text('Основное'));
      await tap(tester, find.byTooltip('Выбрать дату'));
      await tap(tester, find.text('Отмена'));
      expect(find.text('1990-04-12'), findsOneWidget);
      expect(repo.mutations, isEmpty);
      await tap(tester, find.byTooltip('Выбрать дату'));
      await tap(tester, find.text('15').last);
      final label = MaterialLocalizations.of(
        tester.element(find.byType(CalendarDatePicker)),
      ).okButtonLabel;
      await tap(tester, find.text(label));
      expect(find.text('1990-04-15'), findsOneWidget);
      expect(repo.mutations, isEmpty);
      await tap(tester, find.byKey(const Key('profile-save')));
      expect(
        (repo.entries['local-profile']!.record as MedicalProfile).birthDate,
        CalendarDate(1990, 4, 15),
      );
      expect(repo.mutations, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
