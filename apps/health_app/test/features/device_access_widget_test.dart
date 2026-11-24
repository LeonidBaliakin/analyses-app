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
      final model = DeviceAccessViewModel(gateway: gateway);
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
      final model = DeviceAccessViewModel(gateway: gateway);
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
        final model = DeviceAccessViewModel(gateway: gateway);
        addTearDown(model.dispose);
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
        await tester.tap(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byTooltip(language == 'ru' ? 'Закрыть' : 'Close'),
          ),
        );
        await tester.pumpAndSettle();
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
      final model = DeviceAccessViewModel(gateway: gateway);
      addTearDown(model.dispose);
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
      expect(find.text('Coordinates: 59.9300, 30.3300'), findsNWidgets(2));
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
