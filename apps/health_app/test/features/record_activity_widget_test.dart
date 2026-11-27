import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../records_flow_test.dart' show launch, tap;
import '../support/memory_records_repository.dart';

void main() {
  for (final language in [AppLanguage.ru, AppLanguage.en]) {
    testWidgets(
      'diary saves once and returns from the nested editor, ${language.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repository = MemoryRecordsRepository();
        repository.entries['local-profile'] = const RecordEntry(
          MedicalProfile(id: 'local-profile', name: 'Synthetic profile'),
          1,
        );
        final model = await launch(tester, repository, language: language);
        await tap(
          tester,
          find.text(
            language == AppLanguage.ru
                ? 'Дневник измерений'
                : 'Measurement diary',
          ),
        );
        await tester.enterText(
          find.byKey(const ValueKey('diary-0-glucose-first')),
          '5,900',
        );
        await tester.pumpAndSettle();
        // Input survives folding and rotation before confirmation.
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        await tap(
          tester,
          find.text(
            language == AppLanguage.ru
                ? 'Сохранить измерение'
                : 'Save measurement',
          ),
        );
        expect(model.ofKind(RecordKind.measurement), hasLength(1));
        expect(
          (model.ofKind(RecordKind.measurement).single.record
                  as HomeMeasurement)
              .value
              .raw,
          '5,900',
        );
        expect(find.textContaining('— 5,900 mmol/L'), findsOneWidget);
        await tester.tap(
          find.byTooltip(language == AppLanguage.ru ? 'Закрыть' : 'Close').last,
        );
        await tester.pumpAndSettle();
        await tap(
          tester,
          find.text(
            language == AppLanguage.ru
                ? 'Дневник измерений'
                : 'Measurement diary',
          ),
        );
        expect(find.textContaining('— 5,900 mmol/L'), findsOneWidget);
        expect(model.ofKind(RecordKind.measurement), hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
