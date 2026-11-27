import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:design_system/design_system.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:health_app/presentation/reference_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_directory/provider_directory.dart';

import '../support/fake_device_access.dart';

Widget harness(
  DeviceAccessViewModel device,
  DirectoryViewModel directory, {
  String language = 'en',
  bool dark = false,
  bool doctors = false,
}) => DeviceAccessScope(
  model: device,
  child: MaterialApp(
    locale: Locale(language),
    theme: dark ? AppTheme.dark : AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: DirectoryPage(model: directory, doctors: doctors),
    ),
  ),
);

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'doctor specialty selection uses dictionary IDs and survives resize, $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
        final directory = DirectoryViewModel(catalog: bundledDirectory());
        addTearDown(device.dispose);
        addTearDown(directory.dispose);
        await device.setManualLocation('Synthetic confirmed address');
        await tester.pumpWidget(
          harness(device, directory, language: language, doctors: true),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('directory-filters')));
        await tester.pumpAndSettle();
        final label = language == 'ru'
            ? 'Все специальности'
            : 'All specialties';
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(language == 'ru' ? 'Хирург' : 'Surgeon'));
        await tester.pumpAndSettle();
        expect(directory.specialtyId, 'specialty.surgery');
        expect(directory.hits(doctors: true), hasLength(3));
        expect(find.text('Митин Андрей Викторович'), findsNWidgets(3));
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpAndSettle();
        expect(directory.specialtyId, 'specialty.surgery');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'confirmed panel details expose composition and unknown source methods',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
      final directory = DirectoryViewModel(catalog: bundledDirectory());
      addTearDown(device.dispose);
      addTearDown(directory.dispose);
      await device.setManualLocation('Synthetic confirmed address');
      directory.selectCity(DirectoryCity.voronezh);
      directory.toggleTest('test.sova.coagulation');
      await tester.pumpWidget(harness(device, directory, language: 'ru'));
      await tester.pumpAndSettle();
      final details = find.text('Состав, материал и метод').first;
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.textContaining('Фибриноген'), findsWidgets);
      expect(find.text('Метод: Не уточнён источником'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final restored in [false, true]) {
    testWidgets(
      'confirmed ${restored ? 'saved' : 'typed'} address determines distances without selecting a suggestion',
      (tester) async {
        const address = 'Воронеж, Никитинская улица 52';
        final lookup = FakeAddressLookup()
          ..suggestions = [
            const DeviceLocation(
              address: address,
              coordinates: DeviceCoordinates(51.663161383652, 39.189740436175),
              level: AddressLevel.building,
            ),
          ];
        final storage = MemoryLocationRepository()
          ..saved = const DeviceLocation(address: address);
        final device = DeviceAccessViewModel(
          gateway: FakeDeviceAccess()..locationIssue = AccessIssue.denied,
          addressLookup: lookup,
          locationRepository: storage,
        );
        final directory = DirectoryViewModel(catalog: bundledDirectory());
        addTearDown(device.dispose);
        addTearDown(directory.dispose);
        if (restored) {
          await device.restoreLocation();
        } else {
          await device.setManualLocation(
            'Previous address',
            suggestion: const DeviceLocation(
              address: 'Previous address',
              coordinates: DeviceCoordinates(59.93, 30.33),
            ),
          );
        }
        await tester.pumpWidget(harness(device, directory));
        await tester.pumpAndSettle();
        if (restored) {
          await tester.tap(find.byKey(const Key('confirm-location')));
        } else {
          await tester.tap(find.byKey(const Key('choose-directory-location')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('manual-location')),
            address,
          );
          await tester.ensureVisible(
            find.byKey(const Key('apply-manual-location')),
          );
          await tester.tap(find.byKey(const Key('apply-manual-location')));
        }
        await tester.pumpAndSettle();
        expect(directory.hits(doctors: false).first.distanceMeters, 0);
        expect(directory.city, DirectoryCity.voronezh);
        expect(
          directory.hits(doctors: false).first.branch.id,
          'sova-nikitinskaya',
        );
        expect(directory.hits(doctors: false).first.distanceMeters, 0);
        expect(find.textContaining('0 m straight-line'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final language in ['ru', 'en']) {
    testWidgets(
      'a different geocoded address needs visible confirmation, $language',
      (tester) async {
        tester.view.physicalSize = language == 'ru'
            ? const Size(390, 844)
            : const Size(1024, 768);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const address = 'Воронеж, Никитинская улица 52';
        final lookup = FakeAddressLookup()
          ..suggestions = [
            const DeviceLocation(
              address: address,
              coordinates: DeviceCoordinates(51.663161383652, 39.189740436175),
            ),
          ];
        final device = DeviceAccessViewModel(
          gateway: FakeDeviceAccess()..locationIssue = AccessIssue.denied,
          addressLookup: lookup,
        );
        final directory = DirectoryViewModel(catalog: bundledDirectory());
        addTearDown(device.dispose);
        addTearDown(directory.dispose);
        await tester.pumpWidget(
          harness(
            device,
            directory,
            language: language,
            dark: language == 'ru',
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('manual-location')),
          'Воронеж, улица Никитинская, 52',
        );
        await tester.ensureVisible(
          find.byKey(const Key('apply-manual-location')),
        );
        await tester.tap(find.byKey(const Key('apply-manual-location')));
        await tester.pumpAndSettle();
        expect(device.locationConfirmed, isFalse);
        expect(find.byKey(const Key('location-candidate')), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('manual-location')))
              .decoration!
              .errorText,
          isNull,
        );
        await tester.ensureVisible(find.byKey(const Key('confirm-location')));
        await tester.tap(find.byKey(const Key('confirm-location')));
        await tester.pumpAndSettle();
        expect(directory.city, DirectoryCity.voronezh);
        expect(directory.hits(doctors: false).first.distanceMeters, 0);
        expect(find.byKey(const Key('manual-location')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('one test type selects provider synonyms in both UI languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
    final directory = DirectoryViewModel(catalog: bundledDirectory());
    addTearDown(device.dispose);
    addTearDown(directory.dispose);
    await device.setManualLocation('Synthetic confirmed address');
    directory.selectCity(DirectoryCity.voronezh);
    await tester.pumpWidget(harness(device, directory, language: 'ru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Список на сдачу'));
    await tester.pumpAndSettle();
    final filter = find.widgetWithText(OptionChip, 'Общий анализ мочи');
    expect(filter, findsOneWidget);
    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(directory.testIds, {'test.urinalysis'});
    expect(
      directory.hits(doctors: false).map((h) => h.branch.network).toSet(),
      {'helix', 'invitro', 'sova'},
    );
    expect(find.text('Общий анализ мочи с микроскопией'), findsWidgets);
    expect(
      find.text('Анализ мочи общий (с микроскопией осадка)'),
      findsWidgets,
    );
    await tester.pumpWidget(harness(device, directory, language: 'en'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OptionChip, 'Urinalysis'), findsOneWidget);
    expect(directory.testIds, {'test.urinalysis'});
    expect(find.text('Общий анализ мочи с микроскопией'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first test selection does not restore expansion state as a scroll offset',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
      final directory = DirectoryViewModel(catalog: bundledDirectory());
      addTearDown(device.dispose);
      addTearDown(directory.dispose);
      await device.setManualLocation('Synthetic confirmed address');
      directory.selectCity(DirectoryCity.voronezh);
      await tester.pumpWidget(harness(device, directory, language: 'ru'));
      await tester.pumpAndSettle();
      expect(directory.hits(doctors: false), hasLength(29));
      await tester.tap(find.text('Список на сдачу'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          OptionChip,
          'Клинический анализ крови с лейкоцитарной формулой без СОЭ',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(directory.hits(doctors: false), hasLength(7));
      expect(find.byType(ErrorWidget), findsNothing);
      expect(
        find.byKey(const ValueKey('provider-sova-moskovsky:')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('provider-sova-nikitinskaya:')),
        findsOneWidget,
      );
      // Each transition remounts selectable addresses in a different result list.
      final filter = find.widgetWithText(
        OptionChip,
        'Клинический анализ крови с лейкоцитарной формулой без СОЭ',
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(filter);
        await tester.pumpAndSettle();
        expect(directory.hits(doctors: false), hasLength(29));
        expect(tester.takeException(), isNull);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        expect(directory.hits(doctors: false), hasLength(7));
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
      }
    },
  );

  for (final language in ['ru', 'en']) {
    testWidgets(
      'real catalogue filters and retains search through resize, $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final gateway = FakeDeviceAccess();
        final device = DeviceAccessViewModel(gateway: gateway);
        final directory = DirectoryViewModel(catalog: bundledDirectory());
        addTearDown(device.dispose);
        addTearDown(directory.dispose);
        await device.setManualLocation(
          'Санкт-Петербург, Литейный, 55А',
          suggestion: const DeviceLocation(
            address: 'Санкт-Петербург, Литейный, 55А',
            coordinates: DeviceCoordinates(59.935620751817, 30.346451736771),
          ),
        );
        await tester.pumpWidget(
          harness(
            device,
            directory,
            language: language,
            dark: language == 'ru',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('provider-scandinavia-4:')),
          findsOneWidget,
        );
        expect(directory.hits(doctors: false).first.branch.id, 'scandinavia-4');
        expect(directory.hits(doctors: false).first.distanceMeters, 0);
        expect(gateway.locateCalls, 0);
        final search = find.byKey(const Key('directory-lab-search'));
        await tester.enterText(search, 'Ферритин');
        await tester.pumpAndSettle();
        expect(directory.hits(doctors: false), isNotEmpty);
        expect(find.byKey(const Key('provider-scandinavia-4:')), findsNothing);
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, 'Ферритин');
        expect(directory.origin!.latitude, closeTo(59.935620751817, .000001));
        expect(gateway.locateCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'selected address suggestion recalculates city and nearest branch',
    (tester) async {
      const address = 'Воронеж, Никитинская улица, 52';
      final lookup = FakeAddressLookup()
        ..suggestions = [
          const DeviceLocation(
            address: address,
            coordinates: DeviceCoordinates(51.663161383652, 39.189740436175),
          ),
        ];
      final device = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      final directory = DirectoryViewModel(catalog: bundledDirectory());
      addTearDown(device.dispose);
      addTearDown(directory.dispose);
      await device.setManualLocation(
        'Санкт-Петербург',
        suggestion: const DeviceLocation(
          address: 'Санкт-Петербург',
          coordinates: DeviceCoordinates(59.93, 30.33),
        ),
      );
      await tester.pumpWidget(harness(device, directory));
      await tester.pumpAndSettle();
      expect(find.byType(DemoBanner), findsNothing);
      await tester.tap(find.byKey(const Key('choose-directory-location')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('manual-location')),
        'Воронеж Никитинская 52',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text(address));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('apply-manual-location')),
      );
      await tester.tap(find.byKey(const Key('apply-manual-location')));
      await tester.pumpAndSettle();
      expect(directory.city, DirectoryCity.voronezh);
      expect(
        directory.hits(doctors: false).first.branch.id,
        'sova-nikitinskaya',
      );
      expect(directory.hits(doctors: false).first.distanceMeters, 0);
      expect(find.textContaining('0 m straight-line'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'doctor practice has real contacts and external booking command',
    (tester) async {
      final opened = <Uri>[];
      final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
      final directory = DirectoryViewModel(
        catalog: bundledDirectory(),
        openUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      addTearDown(device.dispose);
      addTearDown(directory.dispose);
      await device.setManualLocation(
        'Воронеж',
        suggestion: const DeviceLocation(
          address: 'Воронеж',
          coordinates: DeviceCoordinates(51.663161383652, 39.189740436175),
        ),
      );
      await tester.pumpWidget(harness(device, directory, doctors: true));
      await tester.pumpAndSettle();
      expect(find.text('Самотин Александр Николаевич'), findsOneWidget);
      final book = find.text('Book on website').first;
      await tester.ensureVisible(book);
      await tester.tap(book);
      await tester.pump();
      expect(opened.single.host, 'voronezh.sovamed.ru');
      expect(directory.hits(doctors: true).first.distanceMeters, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('city-level address does not masquerade as a precise origin', (
    tester,
  ) async {
    final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
    final directory = DirectoryViewModel(catalog: bundledDirectory());
    addTearDown(device.dispose);
    addTearDown(directory.dispose);
    await device.setManualLocation(
      'Saint Petersburg',
      suggestion: const DeviceLocation(
        address: 'Saint Petersburg',
        coordinates: DeviceCoordinates(59.93, 30.33),
        isAddressPoint: false,
      ),
    );
    await tester.pumpWidget(harness(device, directory));
    await tester.pumpAndSettle();
    expect(directory.origin, isNull);
    expect(
      directory.hits(doctors: false).every((h) => h.distanceMeters == null),
      isTrue,
    );
    expect(find.textContaining('Select an address suggestion'), findsOneWidget);
  });

  testWidgets('long selected tests fit a narrow display at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final device = DeviceAccessViewModel(gateway: FakeDeviceAccess());
    final directory = DirectoryViewModel(catalog: bundledDirectory());
    addTearDown(device.dispose);
    addTearDown(directory.dispose);
    await device.setManualLocation(
      'Воронеж, Никитинская, 52',
      suggestion: const DeviceLocation(
        address: 'Воронеж, Никитинская, 52',
        coordinates: DeviceCoordinates(51.663161383652, 39.189740436175),
      ),
    );
    await tester.pumpWidget(
      harness(device, directory, language: 'ru', dark: true),
    );
    await tester.pumpAndSettle();
    directory.toggleTest('test.cbc-differential-no-esr');
    await tester.pumpAndSettle();
    expect(directory.hits(doctors: false), isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Список на сдачу'));
    await tester.tap(find.text('Список на сдачу'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
