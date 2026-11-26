import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:health_app/features/account/account.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';

class MemorySession implements SessionStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('storage');
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class FakeAccounts implements AccountGateway {
  bool cloudDown = false;
  @override
  Future<AccountCloudStatus> cloudStatus() async {
    if (cloudDown) throw const AccountFailure('network');
    return const AccountCloudStatus(
      syncAllowed: true,
      storageAllowed: true,
      processingAllowed: true,
      recordsUsed: 2,
      recordLimit: 100,
      bytesUsed: 10,
      bytesReserved: 5,
      storageLimit: 1000,
      jobsUsed: 2,
      jobsReserved: 1,
      jobLimit: 10,
      period: '2026-11',
    );
  }

  final currentSession = const AccountSession(
    ownerId: 'owner-a',
    email: 'synthetic@example.test',
    sessionId: 's1',
    token: 'synthetic-token',
  );
  String? failure;
  int logins = 0, registrations = 0, requests = 0, revokes = 0;
  Completer<AccountSession>? pending;
  @override
  Future<String> challenge(String email, bool recovery) async {
    requests++;
    return 'challenge';
  }

  @override
  Future<AccountSession> login(String e, String p, String l) async {
    logins++;
    if (failure != null) throw AccountFailure(failure!);
    return currentSession;
  }

  @override
  Future<AccountSession> register(
    String id,
    String code,
    String p,
    String l,
  ) async {
    registrations++;
    return currentSession;
  }

  @override
  Future<void> recover(String id, String code, String p) async {}
  @override
  Future<AccountSession> current() async {
    if (pending != null) return pending!.future;
    if (failure != null) throw AccountFailure(failure!);
    return currentSession;
  }

  @override
  Future<List<AccountDevice>> devices() async => [
    AccountDevice('s1', 'Phone', DateTime(2026, 11, 26), true),
    AccountDevice('s2', 'Tablet', DateTime(2026, 11, 26), false),
  ];
  @override
  Future<void> revoke(String id) async {
    revokes++;
  }

  @override
  Future<void> logout({bool all = false}) async {
    if (failure != null) throw AccountFailure(failure!);
  }

  @override
  void close() {}
}

void main() {
  late FakeAccounts api;
  late MemorySession storage;
  late AccountViewModel model;
  int connections = 0, disconnections = 0;
  setUp(() {
    api = FakeAccounts();
    storage = MemorySession();
    connections = 0;
    disconnections = 0;
    model = AccountViewModel(
      endpoint: Uri.parse('https://api.example.test/'),
      gatewayFactory: (_, _) => api,
      storage: storage,
      onConnect: (_) async {
        connections++;
        return true;
      },
      onDisconnect: () {
        disconnections++;
      },
    );
  });
  tearDown(() => model.dispose());
  test('login persists session, explicit cloud connect, logout preserves local records', () async {
    await model.submit(
      'synthetic@example.test',
      'synthetic password',
      'Phone',
      '',
    );
    expect(model.session?.ownerId, 'owner-a');
    expect(storage.value, contains('synthetic-token'));
    expect(connections, 0);
    await model.connectCloud();
    expect(connections, 1);
    expect(model.cloudConnected, true);
    await model.logout();
    expect(disconnections, 1);
    expect(model.session, null);
    expect(storage.value, null);
  });
  test('session restoration validates server, offline retry preserves credential, revocation disconnects', () async {
    storage.value = jsonEncode({
      'endpoint': model.endpoint.toString(),
      'token': 'synthetic-token',
    });
    api.failure = 'network';
    await model.restore();
    expect(storage.value, isNotNull);
    expect(model.session, null);
    api.failure = null;
    await model.restore();
    expect(model.session, isNotNull);
    expect(connections, 0);
    api.failure = 'unauthorized';
    await model.validate();
    expect(disconnections, 1);
    expect(storage.value, null);
    expect(model.error, 'session_expired');
  });
  test('late validation cannot erase a newer session', () async {
    await model.submit(
      'synthetic@example.test',
      'synthetic password',
      'Phone',
      '',
    );
    api.pending = Completer<AccountSession>();
    final validating = model.validate();
    await model.logout();
    await model.submit(
      'synthetic@example.test',
      'synthetic password',
      'Phone',
      '',
    );
    api.pending!.completeError(const AccountFailure('unauthorized'));
    await validating;
    expect(model.session, isNotNull);
    expect(disconnections, 1);
  });
  test(
    'secure storage failure stays visible without losing the active session',
    () async {
      storage.fail = true;
      await model.submit(
        'synthetic@example.test',
        'synthetic password',
        'Phone',
        '',
      );
      expect(model.session, isNotNull);
      expect(model.error, 'secure_storage');
    },
  );
  test('failed quota refresh preserves the last snapshot with an explicit stale state', () async {
    await model.submit(
      'synthetic@example.test',
      'synthetic password',
      'Phone',
      '',
    );
    final last = model.cloud;
    expect(last, isNotNull);
    api.cloudDown = true;
    await model.refreshCloud();
    expect(model.cloud, same(last));
    expect(model.cloudError, 'unavailable');
    expect(model.session, isNotNull);
  });
  test('recovery clears challenge and requires a fresh login', () async {
    model.selectMode(AccountMode.recover);
    await model.requestCode('synthetic@example.test');
    await model.submit(
      'synthetic@example.test',
      'replacement password',
      'Phone',
      '12345678',
    );
    expect(model.mode, AccountMode.login);
    expect(model.session, null);
    expect(model.challengeId, null);
    expect(model.message, 'recovered');
  });
  for (final (locale, dark) in [('ru', false), ('en', true)]) {
    testWidgets(
      'registration and input survive fold, resize and text scaling $locale',
      (tester) async {
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(375, 812);
        Widget app({bool folded = false}) => MaterialApp(
          locale: Locale(locale),
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.4),
              displayFeatures: folded
                  ? const [
                      DisplayFeature(
                        bounds: Rect.fromLTWH(500, 0, 20, 800),
                        type: DisplayFeatureType.hinge,
                        state: DisplayFeatureState.postureFlat,
                      ),
                    ]
                  : const [],
            ),
            child: child!,
          ),
          home: AccountPage(model: model, onClose: () {}, onOpenSync: () {}),
        );
        await tester.pumpWidget(app());
        model.selectMode(AccountMode.register);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('account-email')),
          'synthetic@example.test',
        );
        await tester.ensureVisible(find.byKey(const Key('account-submit')));
        await tester.tap(find.byKey(const Key('account-submit')));
        await tester.pumpAndSettle();
        expect(api.requests, 1);
        expect(find.byKey(const Key('account-code')), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('account-code')),
          '12345678',
        );
        await tester.enterText(
          find.byKey(const Key('account-password')),
          'synthetic long password',
        );
        tester.view.physicalSize = const Size(1020, 800);
        await tester.pumpWidget(app(folded: true));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('account-password')))
              .controller!
              .text,
          'synthetic long password',
        );
        expect(api.requests, 1);
        await tester.ensureVisible(find.byKey(const Key('account-submit')));
        await tester.tap(find.byKey(const Key('account-submit')));
        await tester.pumpAndSettle();
        expect(api.registrations, 1);
        expect(
          find.text(locale == 'ru' ? 'Записей: 2 из 100' : 'Records: 2 of 100'),
          findsOneWidget,
        );
        expect(find.text('synthetic@example.test'), findsOneWidget);
        expect(connections, 0);
        await tester.ensureVisible(find.byKey(const Key('account-connect')));
        await tester.tap(find.byKey(const Key('account-connect')));
        await tester.pumpAndSettle();
        expect(connections, 1);
        expect(tester.takeException(), isNull);
        await model.logout();
        expect(disconnections, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
