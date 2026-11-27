import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_directory/provider_directory.dart';

import '../support/fake_device_access.dart';
import 'directory_widget_test.dart' show harness;

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'refresh failure is visible and retains CSP results, $language',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
        var calls = 0;
        final directory = DirectoryViewModel(
          catalog: bundledDirectory(),
          refreshCatalog: () async {
            calls++;
            throw const FormatException('offline');
          },
        );
        addTearDown(device.dispose);
        addTearDown(directory.dispose);
        await device.setManualLocation('Synthetic confirmed address');
        directory.selectCity(DirectoryCity.voronezh);
        directory.setQuery('ЦСП', doctors: false);
        await tester.pumpWidget(
          harness(
            device,
            directory,
            language: language,
            dark: language == 'en',
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('directory-sources')));
        await tester.tap(find.byKey(const Key('directory-sources')));
        await tester.pumpAndSettle();
        final button = find.text(
          language == 'ru' ? 'Обновить каталог' : 'Refresh directory',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(directory.hits(doctors: false), hasLength(5));
        expect(
          find.text(
            language == 'ru'
                ? 'Обновление недоступно. Показана последняя сохранённая версия.'
                : 'Unable to refresh. Showing the last saved version.',
          ),
          findsOneWidget,
        );
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(directory.labQuery, 'ЦСП');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
