import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:postgres/postgres.dart';
import 'package:record_sync/record_sync.dart';
import 'package:records_service/records_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final file = File('../../infra/documents/.env');
  if (!file.existsSync()) {
    test('PostgreSQL', () {}, skip: 'Start local sync Compose stack');
    return;
  }
  final env = {
    for (final line in file.readAsLinesSync())
      line.split('=').first: line.substring(line.indexOf('=') + 1),
  };
  final db = Pool.withUrl(
    'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/records_tests?sslmode=disable',
  );
  late RecordsService api;
  late String epoch;
  Future<Response> call(
    String method,
    String path, {
    String token = 'a',
    String profile = 'p',
    Map<String, Object?>? body,
  }) => api.call(
    Request(
      method,
      Uri.parse('http://localhost/v1/profiles/$profile/$path'),
      headers: {'authorization': 'Bearer $token'},
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  Map<String, Object?> cmd(
    HealthRecord record, {
    String op = 'operation',
    String device = 'device-a',
    int base = 0,
    bool deleted = false,
  }) => {
    ...SyncCommand(
      operationId: op,
      deviceId: device,
      baseVersion: base,
      payload: Map<String, dynamic>.from(encodeRecord(record)),
      deleted: deleted,
    ).toJson(),
    'epoch': epoch,
  };
  final profile = const MedicalProfile(id: 'p', name: 'Synthetic');
  LabResult lab(String value, {String id = 'r'}) => LabResult(
    id: id,
    profileId: 'p',
    name: 'Synthetic',
    date: CalendarDate(2026, 11, 25),
    value: SourceValue(value, ResultValueKind.numeric),
    category: AnalysisCategory.blood,
    unit: 'mmol/L',
  );
  Future<int> count(String table) async =>
      (await db.execute('SELECT count(*) FROM $table')).single[0] as int;
  setUpAll(() async {
    await RecordsService(db, []).migrate();
  });
  tearDownAll(() => db.close());
  setUp(() async {
    await db.execute(
      'TRUNCATE scopes,records,changes,operations,record_outbox',
    );
    api = RecordsService(db, [
      TokenIdentity('owner-a', sha256.convert(utf8.encode('a')).toString()),
      TokenIdentity('owner-b', sha256.convert(utf8.encode('b')).toString()),
    ]);
    await api.grant('owner-a', 'p');
    await api.grant('owner-b', 'q');
    epoch = (await json(await call('GET', 'sync-access')))['epoch'] as String;
  });
  test(
    'owner/profile/epoch and entitlement checked; no data discarded on denial',
    () async {
      expect(
        (await call('GET', 'sync-access', token: 'invalid')).statusCode,
        401,
      );
      expect((await call('GET', 'sync-access', token: 'b')).statusCode, 404);
      expect(
        (await call(
          'POST',
          'sync-operations',
          body: {...cmd(profile), 'epoch': 'other'},
        )).statusCode,
        409,
      );
      await db.execute(
        "UPDATE scopes SET can_write=false WHERE owner_id='owner-a'",
      );
      expect(
        (await call('POST', 'sync-operations', body: cmd(profile))).statusCode,
        403,
      );
      expect(await count('records'), 0);
      expect(
        (await call('GET', 'sync-changes?cursor=0&epoch=$epoch')).statusCode,
        200,
      );
    },
  );
  test('concurrent replay is one mutation/event; changed operation and schema fail', () async {
    await call('POST', 'sync-operations', body: cmd(profile, op: 'profile'));
    final body = cmd(lab('0,0100'));
    final responses = await Future.wait(
      List.generate(5, (_) => call('POST', 'sync-operations', body: body)),
    );
    expect(responses.map((r) => r.statusCode), everyElement(200));
    for (final response in responses) {
      expect((await json(response))['applied'], isTrue);
    }
    expect(await count('records'), 2);
    expect(await count('changes'), 2);
    expect(await count('record_outbox'), 2);
    expect(
      (await call(
        'POST',
        'sync-operations',
        body: cmd(lab('0,0200')),
      )).statusCode,
      409,
    );
    final reversed = {
      for (final entry in (body['payload'] as Map).entries.toList().reversed)
        entry.key: entry.value,
    };
    expect(
      (await call(
        'POST',
        'sync-operations',
        body: {...body, 'payload': reversed},
      )).statusCode,
      200,
    );
    expect(
      (await call(
        'POST',
        'sync-operations',
        body: {
          ...cmd(lab('1'), op: 'invalid'),
          'payload': {...encodeRecord(lab('1')), 'format': 99},
        },
      )).statusCode,
      400,
    );
  });
  test('CAS edit/delete/explicit restore conflicts preserve immutable history and ordered changes', () async {
    await call('POST', 'sync-operations', body: cmd(profile, op: 'profile'));
    await call('POST', 'sync-operations', body: cmd(lab('5'), op: 'create'));
    final conflict = await json(
      await call(
        'POST',
        'sync-operations',
        body: cmd(lab('7'), op: 'other', device: 'b', base: 0),
      ),
    );
    expect(conflict['applied'], isFalse);
    expect((conflict['current'] as Map)['payload']['raw'], '5');
    await call(
      'POST',
      'sync-operations',
      body: cmd(lab('6'), op: 'edit', base: 1),
    );
    final deletion = await json(
      await call(
        'POST',
        'sync-operations',
        body: cmd(lab('6'), op: 'delete', base: 2, deleted: true),
      ),
    );
    expect(deletion['applied'], isTrue);
    final stale = await json(
      await call(
        'POST',
        'sync-operations',
        body: cmd(lab('8'), op: 'stale', device: 'b', base: 2),
      ),
    );
    expect(stale['applied'], isFalse);
    expect(stale['current']['deleted'], isTrue);
    expect(
      (await json(
        await call(
          'POST',
          'sync-operations',
          body: cmd(lab('8'), op: 'restore', device: 'b', base: 3),
        ),
      ))['applied'],
      isTrue,
    );
    final changes = await json(
      await call('GET', 'sync-changes?cursor=0&epoch=$epoch'),
    );
    expect((changes['records'] as List).map((r) => r['sequence']), [
      1,
      2,
      3,
      4,
      5,
    ]);
    expect(changes['cursor'], 5);
    expect(changes['more'], isFalse);
    final oldReplay = await json(
      await call(
        'POST',
        'sync-operations',
        body: cmd(lab('7'), op: 'other', device: 'b', base: 0),
      ),
    );
    expect(oldReplay, conflict);
    expect(await count('changes'), 5);
  });
  test('outbox failure rolls back record, receipt and cursor; retry succeeds exactly once', () async {
    await db.execute(
      r"CREATE FUNCTION fail_outbox() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'synthetic'; END $$",
    );
    await db.execute(
      'CREATE TRIGGER fail_outbox BEFORE INSERT ON record_outbox FOR EACH ROW EXECUTE FUNCTION fail_outbox()',
    );
    try {
      expect(
        (await call('POST', 'sync-operations', body: cmd(profile))).statusCode,
        503,
      );
      expect(await count('records'), 0);
      expect(await count('changes'), 0);
      expect(await count('operations'), 0);
      expect(
        (await db.execute("SELECT head FROM scopes WHERE owner_id='owner-a'"))
            .single[0],
        0,
      );
    } finally {
      await db.execute('DROP TRIGGER fail_outbox ON record_outbox');
      await db.execute('DROP FUNCTION fail_outbox()');
    }
    expect(
      (await call('POST', 'sync-operations', body: cmd(profile))).statusCode,
      200,
    );
    expect(await count('record_outbox'), 1);
  });
}
