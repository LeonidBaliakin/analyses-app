import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../records_flow_test.dart' show launch, tap, enter;
import '../support/memory_records_repository.dart';

void main() {
  for (final language in [AppLanguage.ru, AppLanguage.en]) {
    testWidgets(
      'diary saves once and returns from the nested editor, ${language.name}',
      (tester) async {
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
        await tap(
          tester,
          find.text(
            language == AppLanguage.ru
                ? 'Добавить измерение'
                : 'Add measurement',
          ),
        );
        await enter(tester, 'name', 'Synthetic measurement');
        await enter(tester, 'value', '5,900');
        await enter(tester, 'unit', 'original unit');
        await tap(tester, find.byKey(const Key('record-save')));
        expect(model.ofKind(RecordKind.measurement), hasLength(1));
        expect(
          (model.ofKind(RecordKind.measurement).single.record
                  as HomeMeasurement)
              .value
              .raw,
          '5,900',
        );
        expect(find.textContaining('Synthetic measurement'), findsOneWidget);
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
        expect(find.textContaining('Synthetic measurement'), findsOneWidget);
        expect(model.ofKind(RecordKind.measurement), hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
