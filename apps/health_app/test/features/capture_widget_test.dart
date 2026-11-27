import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/capture/src/event_capture_view.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../records_flow_test.dart' show launch, tap;
import '../support/memory_records_repository.dart';

void main() {
  testWidgets(
    'event story survives folding, review is separate from atomic confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MemoryRecordsRepository();
      repo.entries['local-profile'] = const RecordEntry(
        MedicalProfile(
          id: 'local-profile',
          name: 'Synthetic',
          history: 'Original',
        ),
        1,
      );
      await launch(tester, repo, language: AppLanguage.ru);
      await tap(tester, find.text('Добавить событие'));
      const story = 'Вчера болел ОРВИ; вчера принимал витамин D';
      await tester.enterText(find.byKey(const ValueKey('event-story')), story);
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.text(story), findsOneWidget);
      await tap(tester, find.text('Проверить записи'));
      expect(repo.mutations, isEmpty);
      final m = tester
          .widget<EventCaptureView>(find.byType(EventCaptureView))
          .model;
      expect(m.rows, hasLength(2));
      repo.writeGate = Completer<void>();
      await tap(tester, find.text('Подтвердить и сохранить'));
      expect(m.saving, isTrue);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Подтвердить и сохранить'),
            )
            .onPressed,
        isNull,
      );
      repo.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(repo.mutations, hasLength(2));
      expect(
        repo.entries.values.where((e) => e.record is MedicationCourse),
        hasLength(1),
      );
      final p = repo.entries['local-profile']!.record as MedicalProfile;
      expect(p.history, 'Original');
      expect(p.details!.events.single.name, contains('ОРВИ'));
      expect(
        p.details!.events.single.fields[ProfileEventField.sourceText],
        contains('Вчера болел ОРВИ'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
