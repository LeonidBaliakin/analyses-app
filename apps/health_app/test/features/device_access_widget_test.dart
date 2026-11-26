import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:design_system/design_system.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/capture/capture.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../support/fake_device_access.dart';

Widget harness(
  DeviceAccessViewModel model, {
  String language = 'en',
  bool dark = false,
  Widget? home,
}) => DeviceAccessScope(
  model: model,
  child: MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: Locale(language),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home:
        home ??
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddAnalysis(context),
              child: const Text('Add document'),
            ),
          ),
        ),
  ),
);

void main() {
  testWidgets('address lookup errors remain visible with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess(),
      addressLookup: FakeAddressLookup()..fail = true,
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      harness(
        model,
        language: 'ru',
        home: const Scaffold(body: DirectoryPage()),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('manual-location'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Вор');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(
      find
          .text('Подсказки адресов недоступны. Можно ввести адрес вручную.')
          .hitTestable(),
      findsOneWidget,
    );
  });
  testWidgets('address suggestions become visible above the Android keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);
    final lookup = FakeAddressLookup()
      ..suggestions = [
        const DeviceLocation(address: 'Воронеж, Воронежская область, Россия'),
      ];
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess()..locationIssue = AccessIssue.denied,
      addressLookup: lookup,
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      harness(
        model,
        language: 'ru',
        home: const Scaffold(body: DirectoryPage()),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('manual-location'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Вор');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(
      find.text('Воронеж, Воронежская область, Россия').hitTestable(),
      findsOneWidget,
    );
    expect(tester.getBottomLeft(field).dy, lessThan(812 - 320));
  });
  testWidgets(
    'address input progresses city to street to building below the field',
    (tester) async {
      const city = DeviceLocation(
        address: 'Воронеж, Воронежская область, Россия',
        completion: 'Воронеж, ',
        level: AddressLevel.city,
      );
      const street = DeviceLocation(
        address: 'Воронеж, улица Ленина, Россия',
        completion: 'Воронеж, улица Ленина, ',
        level: AddressLevel.street,
      );
      const building = DeviceLocation(
        address: 'Воронеж, улица Ленина 10, Россия',
        completion: 'Воронеж, улица Ленина 10',
        level: AddressLevel.building,
        coordinates: DeviceCoordinates(51.6, 39.2),
      );
      final lookup = FakeAddressLookup()
        ..onSearch = (query) async => [
          query.endsWith('10')
              ? building
              : query.contains('Лен')
              ? street
              : city,
        ];
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        harness(
          model,
          language: 'ru',
          home: Scaffold(
            body: SingleChildScrollView(child: LocationControls(model: model)),
          ),
        ),
      );
      final field = find.byKey(const Key('manual-location'));
      for (final (query, result, helper) in [
        ('Вор', city, 'Город выбран. Теперь введите улицу.'),
        ('Воронеж, Лен', street, 'Улица выбрана. Теперь введите номер дома.'),
        (
          'Воронеж, улица Ленина, 10',
          building,
          'Адрес выбран. Подтвердите его кнопкой ниже.',
        ),
      ]) {
        await tester.enterText(field, query);
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(const Key('address-suggestions'))).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(field).dy),
        );
        await tester.ensureVisible(find.text(result.address));
        await tester.tap(find.text(result.address));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          result.inputText,
        );
        expect(find.text(helper), findsOneWidget);
        expect(model.locationConfirmed, isFalse);
      }
      await tester.ensureVisible(
        find.byKey(const Key('apply-manual-location')),
      );
      await tester.tap(find.byKey(const Key('apply-manual-location')));
      await tester.pumpAndSettle();
      expect(model.location!.address, building.address);
      expect(model.coordinates!.latitude, 51.6);
      expect(tester.takeException(), isNull);
    },
  );
  for (final language in ['ru', 'en']) {
    for (final gpsAvailable in [false, true]) {
      testWidgets(
        'new session confirms ${gpsAvailable ? 'GPS' : 'last saved'} address, $language',
        (tester) async {
          final storage = MemoryLocationRepository()
            ..saved = const DeviceLocation(address: 'Казань, улица Баумана, 1');
          final gateway = FakeDeviceAccess();
          if (!gpsAvailable) gateway.locationIssue = AccessIssue.denied;
          final model = DeviceAccessViewModel(
            gateway: gateway,
            addressLookup: FakeAddressLookup(),
            locationRepository: storage,
          );
          addTearDown(model.dispose);
          await model.restoreLocation();
          await tester.pumpWidget(
            harness(
              model,
              language: language,
              dark: language == 'ru',
              home: const Scaffold(body: DirectoryPage()),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              language == 'ru' ? 'Вы находитесь здесь?' : 'Are you here?',
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<Text>(find.byKey(const Key('location-candidate')))
                .data,
            gpsAvailable
                ? 'Санкт-Петербург, Невский проспект, 1'
                : 'Казань, улица Баумана, 1',
          );
          expect(model.locationConfirmed, isFalse);
          expect(gateway.requestedLocationPermission, isFalse);
          await tester.tap(find.byKey(const Key('confirm-location')));
          await tester.pumpAndSettle();
          expect(model.locationConfirmed, isTrue);
          expect(find.byType(Dialog), findsNothing);
          // Both directory tabs share confirmation for the current app session.
          await tester.pumpWidget(
            harness(
              model,
              language: language,
              home: const Scaffold(
                body: DirectoryPage(doctors: true, key: ValueKey('doctors')),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing);
          expect(gateway.locateCalls, 1);
          expect(find.textContaining('59.93'), findsNothing);
        },
      );
    }
  }

  testWidgets(
    'address suggestions support keyboard selection and explicit confirmation',
    (tester) async {
      final lookup = FakeAddressLookup()
        ..suggestions = [
          const DeviceLocation(
            address: 'Kazan, Baumana Street 1',
            coordinates: DeviceCoordinates(55.8, 49.1),
          ),
        ];
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        harness(
          model,
          home: Scaffold(
            body: SingleChildScrollView(child: LocationControls(model: model)),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('manual-location')),
        'Kazan Bau',
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Kazan, Baumana Street 1'), findsOneWidget);
      final field = tester.getRect(find.byKey(const Key('manual-location')));
      final menu = tester.getRect(find.byKey(const Key('address-suggestions')));
      expect(menu.top, closeTo(field.bottom, 1));
      expect(menu.width, closeTo(field.width, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('manual-location')))
            .controller!
            .text,
        'Kazan, Baumana Street 1',
      );
      expect(model.locationConfirmed, isFalse);
      await tester.ensureVisible(
        find.byKey(const Key('apply-manual-location')),
      );
      await tester.tap(find.byKey(const Key('apply-manual-location')));
      await tester.pumpAndSettle();
      expect(model.location!.address, 'Kazan, Baumana Street 1');
      expect(model.coordinates!.latitude, 55.8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'suggestions stay below the field even near the bottom of the viewport',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final lookup = FakeAddressLookup()
        ..suggestions = [const DeviceLocation(address: 'Voronezh, Russia')];
      final model = DeviceAccessViewModel(
        gateway: FakeDeviceAccess(),
        addressLookup: lookup,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        harness(
          model,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 450),
                child: LocationControls(model: model),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('manual-location')),
        'Voronezh',
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byKey(const Key('manual-location')));
      final menu = tester.getRect(find.byKey(const Key('address-suggestions')));
      expect(menu.top, closeTo(field.bottom, 1));
      expect(menu.width, closeTo(field.width, 1));
      await tester.tap(find.text('Voronezh, Russia'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('manual-location')))
            .controller!
            .text,
        'Voronezh, Russia',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'declining saved address keeps manual input through narrow/wide resizing',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final storage = MemoryLocationRepository()
        ..saved = const DeviceLocation(address: 'Казань');
      final gateway = FakeDeviceAccess()
        ..locationIssue = AccessIssue.serviceDisabled;
      final model = DeviceAccessViewModel(
        gateway: gateway,
        locationRepository: storage,
      );
      addTearDown(model.dispose);
      await model.restoreLocation();
      await tester.pumpWidget(
        harness(
          model,
          language: 'ru',
          dark: true,
          home: const Scaffold(body: DirectoryPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('edit-location')));
      await tester.tap(find.byKey(const Key('edit-location')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('manual-location')));
      await tester.enterText(
        find.byKey(const Key('manual-location')),
        'Новый адрес',
      );
      tester.view.physicalSize = const Size(900, 500);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('manual-location')))
            .controller!
            .text,
        'Новый адрес',
      );
      expect(gateway.locateCalls, 1);
      await tester.ensureVisible(
        find.byKey(const Key('apply-manual-location')),
      );
      await tester.tap(find.byKey(const Key('apply-manual-location')));
      await tester.pumpAndSettle();
      expect(storage.saved!.address, 'Новый адрес');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'startup offers files and location and can continue without permissions',
    (tester) async {
      final gateway = FakeDeviceAccess();
      final model = DeviceAccessViewModel(
        gateway: gateway,
        introductionRequired: true,
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(
        harness(
          model,
          home: const DeviceAccessIntroduction(
            child: Scaffold(body: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Device access'), findsOneWidget);
      expect(find.text('Choose a file'), findsOneWidget);
      expect(find.byKey(const Key('locate-device')), findsOneWidget);
      expect(gateway.pickCalls, 0);
      expect(gateway.locateCalls, 0);
      await tester.tap(find.byKey(const Key('access-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Device access'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(model.introductionRequired, isFalse);
      expect(gateway.locateCalls, 0);
    },
  );

  testWidgets(
    'capture requests only selected source, shows refusal and preserves selection on close',
    (tester) async {
      final gateway = FakeDeviceAccess()..pickIssue = AccessIssue.denied;
      final model = DeviceAccessViewModel(
        gateway: gateway,
        addressLookup: FakeAddressLookup(),
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(harness(model));
      await tester.tap(find.text('Add document'));
      await tester.pumpAndSettle();
      expect(gateway.pickCalls, 0);
      await tester.tap(find.text('Photograph a report'));
      await tester.pumpAndSettle();
      expect(gateway.lastSource, AttachmentSource.camera);
      expect(find.textContaining('Access was denied.'), findsOneWidget);
      gateway.pickIssue = null;
      gateway.selection = syntheticAttachment();
      await tester.tap(find.text('File or PDF'));
      await tester.pumpAndSettle();
      expect(gateway.lastSource, AttachmentSource.files);
      expect(find.text('synthetic-report.pdf'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add document'));
      await tester.pumpAndSettle();
      expect(find.text('synthetic-report.pdf'), findsOneWidget);
      expect(gateway.pickCalls, 2);
    },
  );

  testWidgets(
    'unsupported camera has an explanation and files remain available',
    (tester) async {
      final gateway = FakeDeviceAccess()..supportsCamera = false;
      final model = DeviceAccessViewModel(
        gateway: gateway,
        addressLookup: FakeAddressLookup(),
      );
      addTearDown(model.dispose);
      await tester.pumpWidget(harness(model));
      await tester.tap(find.text('Add document'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Taking photos is unavailable'),
        findsOneWidget,
      );
      final camera = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Photograph a report'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(camera.onPressed, isNull);
      await tester.tap(find.text('File or PDF'));
      await tester.pumpAndSettle();
      expect(gateway.pickCalls, 1);
      expect(
        find.text('Selection cancelled. No file was added.'),
        findsOneWidget,
      );
    },
  );

  for (final language in ['ru', 'en']) {
    testWidgets(
      'directory supports manual address after denied location, $language',
      (tester) async {
        final gateway = FakeDeviceAccess()
          ..locationIssue = AccessIssue.permanentlyDenied;
        final model = DeviceAccessViewModel(
          gateway: gateway,
          addressLookup: FakeAddressLookup(),
        );
        addTearDown(model.dispose);
        await model.setManualLocation('Предыдущий адрес');
        await tester.pumpWidget(
          harness(
            model,
            language: language,
            dark: language == 'ru',
            home: const Scaffold(body: DirectoryPage()),
          ),
        );
        await tester.tap(find.byKey(const Key('choose-directory-location')));
        await tester.pumpAndSettle();
        expect(gateway.locateCalls, 0);
        await tester.tap(find.byKey(const Key('locate-device')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('manual-location')),
          'Казань, улица Баумана',
        );
        await tester.ensureVisible(
          find.byKey(const Key('apply-manual-location')),
        );
        await tester.tap(find.byKey(const Key('apply-manual-location')));
        await tester.pumpAndSettle();
        expect(model.manualLocation, 'Казань, улица Баумана');
        expect(model.locationIssue, isNull);
        expect(gateway.locateCalls, 1);
        expect(find.text('Казань, улица Баумана'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'manual input survives resizing and no location request repeats',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gate = Completer<DeviceCoordinates>();
      final gateway = FakeDeviceAccess()..pendingLocation = gate.future;
      final model = DeviceAccessViewModel(
        gateway: gateway,
        addressLookup: FakeAddressLookup(),
      );
      addTearDown(model.dispose);
      await model.setManualLocation('Предыдущий адрес');
      await tester.pumpWidget(
        harness(model, home: const Scaffold(body: DirectoryPage())),
      );
      await tester.tap(find.byKey(const Key('choose-directory-location')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('manual-location')),
        'Казань',
      );
      await tester.tap(find.byKey(const Key('locate-device')));
      await tester.pump();
      tester.view.physicalSize = const Size(900, 700);
      await tester.pump();
      expect(gateway.locateCalls, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('manual-location')))
            .controller!
            .text,
        'Казань',
      );
      gate.complete(const DeviceCoordinates(59.93, 30.33));
      await tester.pumpAndSettle();
      expect(find.text('Санкт-Петербург, Невский проспект, 1'), findsOneWidget);
      expect(find.text('Are you here?'), findsOneWidget);
      expect(find.textContaining('59.9300'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup fits narrow display with large Russian text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final model = DeviceAccessViewModel(
      gateway: FakeDeviceAccess(),
      introductionRequired: true,
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      harness(
        model,
        language: 'ru',
        dark: true,
        home: const DeviceAccessIntroduction(child: Scaffold()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('access-continue')));
    await tester.pumpAndSettle();
    expect(model.introductionRequired, isFalse);
  });
}
