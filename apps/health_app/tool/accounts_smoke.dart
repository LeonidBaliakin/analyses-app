// Synthetic local-only account/recovery and two-SQLite-device probe.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:health_app/data/account/http_account_gateway.dart';
import 'package:health_app/features/account/account_models.dart';
import 'package:health_app/data/sync/http_sync_gateway.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:uuid/uuid.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final endpoint = Uri.parse('http://127.0.0.1:18088/'),
      mailbox = Uri.parse('http://127.0.0.1:18025/');
  final httpClient = http.Client(),
      aAccount = HttpAccountGateway(endpoint),
      bAccount = HttpAccountGateway(endpoint);
  final email = 'synthetic-${const Uuid().v4()}@example.test';
  const password = 'synthetic account password';
  final temp = await Directory.systemTemp.createTemp('analyses-accounts-');
  final a = RecordsDatabase(NativeDatabase(File('${temp.path}/a.sqlite'))),
      b = RecordsDatabase(NativeDatabase(File('${temp.path}/b.sqlite')));
  final gateways = <HttpSyncGateway>[];
  Future<String> code() async {
    for (var n = 0; n < 100; n++) {
      final response = await httpClient.get(mailbox.resolve('api/v1/messages'));
      final list = (jsonDecode(response.body) as Map)['messages'] as List;
      for (final m in list) {
        if ((m['To'] as List).any((r) => r['Address'] == email)) {
          final content = await httpClient.get(
            mailbox.resolve('api/v1/message/${m['ID']}'),
          );
          final text = (jsonDecode(content.body) as Map)['Text'] as String;
          final match = RegExp(r'Code: (\d{8})').firstMatch(text);
          if (match != null) return match[1]!;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('Local SMTP message not delivered');
  }

  HttpSyncGateway sync(AccountSession session) {
    final g = HttpSyncGateway(
      endpoint: endpoint,
      token: session.token,
      profileId: 'local-profile',
    );
    gateways.add(g);
    return g;
  }

  Future<void> run(RecordsDatabase db, HttpSyncGateway g) =>
      SyncRunner(db, g, 'local-profile', DateTime.now).run(force: true);
  try {
    final challenge = await aAccount.challenge(email, false);
    final aSession = await aAccount.register(
      challenge,
      await code(),
      password,
      'Synthetic phone',
    );
    final bSession = await bAccount.login(email, password, 'Synthetic tablet');
    check(aSession.ownerId == bSession.ownerId, 'second device owner');
    check((await aAccount.devices()).length == 2, 'independent sessions');
    final ag = sync(aSession), bg = sync(bSession);
    final identity = await ag.identity();
    check((await bg.identity()).epoch == identity.epoch, 'stable shared scope');
    for (final db in [a, b]) {
      await db.bindSync(
        'local-profile',
        'synthetic:${aSession.ownerId}',
        const Uuid().v4(),
        identity,
      );
    }
    await a.commit(
      RecordMutation(
        operationId: const Uuid().v4(),
        record: const MedicalProfile(
          id: 'local-profile',
          name: 'SYNTHETIC account probe',
        ),
        expectedRevision: 0,
      ),
    );
    final id = const Uuid().v4();
    await a.commit(
      RecordMutation(
        operationId: const Uuid().v4(),
        record: LabResult(
          id: id,
          profileId: 'local-profile',
          name: 'SYNTHETIC marker',
          date: CalendarDate(2026, 11, 26),
          value: const SourceValue('< 0,0100', ResultValueKind.comparison),
          category: AnalysisCategory.blood,
          unit: 'unknown',
        ),
        expectedRevision: 0,
      ),
    );
    await run(a, ag);
    await run(b, bg);
    await run(a, ag);
    await run(b, bg);
    final results = (await b.read('local-profile'))
        .where((e) => e.record is LabResult)
        .toList();
    check(
      results.length == 1 &&
          (results.single.record as LabResult).value.raw == '< 0,0100',
      'exact source value and no duplicates',
    );
    final foreign = await httpClient.get(
      endpoint.resolve('v1/profiles/foreign/sync-access'),
      headers: {'authorization': 'Bearer ${aSession.token}'},
    );
    check(foreign.statusCode == 404, 'foreign profile isolation');
    final mismatch = await httpClient.post(
      endpoint.resolve('v1/profiles/local-profile/uploads'),
      headers: {
        'authorization': 'Bearer ${aSession.token}',
        'x-account-owner': 'different-account',
        'content-type': 'application/json',
      },
      body: '{}',
    );
    check(
      mismatch.statusCode == 401,
      'web account-change guard before accepting a document',
    );
    await aAccount.revoke(bSession.sessionId);
    try {
      await bAccount.current();
      throw StateError('revoked session accepted');
    } on AccountFailure catch (e) {
      check(e.code == 'unauthorized', 'revocation status');
    }
    check(
      (await b.read('local-profile')).length == 2,
      'local history survives revocation',
    );
    final recovery = await aAccount.challenge(email, true);
    // Wait for the new message rather than accidentally reusing the registration code.
    await Future<void>.delayed(const Duration(seconds: 3));
    final nextCode = await code();
    await aAccount.recover(
      recovery,
      nextCode,
      'synthetic replacement password',
    );
    try {
      await ag.identity();
      throw StateError('pre-recovery session accepted');
    } on SyncFailure catch (e) {
      check(e.code == 'unauthorized', 'old session rejected by Documents');
    }
    final recovered = await bAccount.login(
      email,
      'synthetic replacement password',
      'Recovered tablet',
    );
    check(
      recovered.ownerId == aSession.ownerId,
      'recovery keeps the same medical owner',
    );
    final restored = sync(recovered);
    await restored.identity();
    await run(b, restored);
    check(
      (await b.read('local-profile')).length == 2,
      'cloud records survive recovery',
    );
    await bAccount.logout(all: true);
    stdout.writeln(
      'Accounts smoke passed: email verification, two SQLite devices, source precision, isolation, revoke, recovery and data retention.',
    );
  } finally {
    for (final gateway in gateways) {
      gateway.close();
    }
    aAccount.close();
    bAccount.close();
    httpClient.close();
    await a.close();
    await b.close();
    await temp.delete(recursive: true);
  }
}
