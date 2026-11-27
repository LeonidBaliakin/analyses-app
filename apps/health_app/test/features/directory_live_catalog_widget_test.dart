import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_directory/provider_directory.dart';

import '../support/fake_device_access.dart';
import 'directory_widget_test.dart' show harness;

ProviderCatalog liveCatalog() => ProviderCatalog.fromJson({
  'schemaVersion': 1,
  'version': 'synthetic-refresh',
  'checkedAt': '2026-11-20',
  'publishedAt': '2026-11-27T10:30:00Z',
  'branches': [
    for (final network in ['helix', 'invitro'])
      {
        'id': network,
        'network': network,
        'city': 'spb',
        'name': 'Synthetic $network',
        'address': 'Synthetic branch address',
        'phone': network == 'helix' ? '' : '+7 000 000 00 00',
        'phoneScope': 'network',
        'website': 'https://example.org/$network',
        'source': 'https://example.org/$network',
        'checkedAt': '2026-11-26',
      },
  ],
  'doctors': [
    {
      'id': 'doctor',
      'name': 'Synthetic Doctor',
      'specialty': 'Synthetic specialty',
      'branchIds': ['invitro'],
      'checkedAt': '2026-11-21',
      'source': 'https://example.org/doctor',
    },
  ],
  'tests': <Map<String, dynamic>>[],
});

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets('network selection survives refresh and resize, $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
      final model = DirectoryViewModel(
        catalog: liveCatalog(),
        refreshCatalog: () async => liveCatalog(),
      );
      addTearDown(device.dispose);
      addTearDown(model.dispose);
      await device.setManualLocation('Synthetic confirmed location');
      await tester.pumpWidget(
        harness(device, model, language: language, dark: language == 'en'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('directory-filters')));
      await tester.pumpAndSettle();
      final network = find.byKey(const Key('directory-network'));
      await tester.ensureVisible(network);
      await tester.tap(
        find.text(language == 'ru' ? 'Все сети' : 'All networks'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Хеликс'));
      await tester.pumpAndSettle();
      expect(model.networkId, 'helix');
      expect(find.text('Synthetic helix'), findsOneWidget);
      expect(find.text('Synthetic invitro'), findsNothing);
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
      final context = tester.element(find.byType(DirectoryPage));
      final l = AppLocalizations.of(context);
      await tester.ensureVisible(find.text(l.directoryContactsAndSource));
      await tester.tap(find.text(l.directoryContactsAndSource));
      await tester.pumpAndSettle();
      expect(find.text(l.directoryPhoneUnavailable), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('directory-sources')));
      await tester.tap(find.byKey(const Key('directory-sources')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('directory-publication-date')),
        findsOneWidget,
      );
      await model.refresh();
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(model.networkId, 'helix');
      expect(find.text('Synthetic invitro'), findsNothing);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(model.networkId, 'helix');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'publication, branch and doctor dates remain distinct, $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
        final model = DirectoryViewModel(catalog: liveCatalog());
        addTearDown(device.dispose);
        addTearDown(model.dispose);
        await device.setManualLocation('Synthetic confirmed location');
        await tester.pumpWidget(
          harness(
            device,
            model,
            language: language,
            doctors: true,
            dark: language == 'en',
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(DirectoryPage)),
        );
        await tester.ensureVisible(find.text(l.directoryContactsAndSource));
        await tester.tap(find.text(l.directoryContactsAndSource));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('directory-sources')));
        await tester.tap(find.byKey(const Key('directory-sources')));
        await tester.pumpAndSettle();
        final dates = [27, 20, 26, 21]
            .map(
              (day) =>
                  DateFormat.yMMMd(language).format(DateTime(2026, 11, day)),
            )
            .toList();
        expect(find.text(l.directoryPublished(dates[0])), findsOneWidget);
        expect(find.text(l.directorySnapshot(dates[1])), findsOneWidget);
        expect(find.text(l.directorySourceChecked(dates[2])), findsOneWidget);
        expect(find.text(l.directoryDoctorChecked(dates[3])), findsOneWidget);
        expect(find.text(l.directoryNetworkPhone), findsOneWidget);
        expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
