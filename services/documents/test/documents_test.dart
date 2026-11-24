import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:documents_service/documents_service.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class MemoryObjects implements ObjectStorage {
  final data = <String, Uint8List>{};
  bool losePublishResponse = false;
  @override
  Future<Uint8List?> get(String key) async =>
      data[key] == null ? null : Uint8List.fromList(data[key]!);
  @override
  Future<void> put(String key, Uint8List bytes) async {
    data[key] = Uint8List.fromList(bytes);
    if (losePublishResponse && key.startsWith('originals/')) {
      losePublishResponse = false;
      throw const ApiError(503, 'synthetic_disconnect');
    }
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

void main() {
  final envFile = File('../../infra/documents/.env');
  if (!envFile.existsSync()) {
    test(
      'local PostgreSQL integration requires init_dev.py',
      () {},
      skip: 'Start the local Documents stack first.',
    );
    return;
  }
  final env = {
    for (final line in envFile.readAsLinesSync())
      line.split('=').first: line.substring(line.indexOf('=') + 1),
  };
  final db = Pool.withUrl(
    'postgresql://documents:${env['POSTGRES_PASSWORD']}@127.0.0.1:55438/documents_tests?sslmode=disable',
  );
  late MemoryObjects objects;
  late DocumentsStore store;
  late DocumentsService service;
  final now = DateTime.utc(2026, 11, 24);
  final bytes = Uint8List.fromList(
    utf8.encode('%PDF-1.7\nSynthetic test\n%%EOF'),
  );
  UploadMetadata metadata({String id = 'o'}) => UploadMetadata({
    'documentId': 'd-$id',
    'originalId': id,
    'fileName': '../../source.pdf',
    'mime': 'application/pdf',
    'size': bytes.length,
    'sha256': digest(bytes),
    'importSource': 'files',
    'importedAt': now.toIso8601String(),
  });
  Future<Response> call(
    String method,
    String path, {
    String token = 'a-token',
    Object? json,
    List<int>? body,
    Map<String, String> headers = const {},
  }) => service.call(
    Request(
      method,
      Uri.parse('http://localhost/v1/profiles/$path'),
      headers: {'authorization': 'Bearer $token', ...headers},
      body: body ?? (json == null ? null : jsonEncode(json)),
    ),
  );
  setUpAll(() async {
    await DocumentsStore(db, MemoryObjects()).migrate();
  });
  tearDownAll(() => db.close());
  setUp(() async {
    await db.execute(
      'TRUNCATE document_outbox,uploads,profile_access,accounts CASCADE',
    );
    objects = MemoryObjects();
    store = DocumentsStore(db, objects, clock: () => now);
    await store.grant('a', 'p', 1000);
    await store.grant('b', 'q', 1000);
    service = DocumentsService(
      store,
      identities: [
        TokenIdentity('a', sha256.convert(utf8.encode('a-token')).toString()),
        TokenIdentity('b', sha256.convert(utf8.encode('b-token')).toString()),
      ],
      allowedOrigins: {'http://localhost:7357'},
    );
  });
  Future<void> staged() async {
    expect(
      (await call('POST', 'p/uploads', json: metadata().toJson())).statusCode,
      200,
    );
    expect(
      (await call('PUT', 'p/uploads/o/content', body: bytes)).statusCode,
      200,
    );
  }

  test('HTTP contract: replay, finalization, full and ranged reads, private access', () async {
    await staged();
    for (var i = 0; i < 2; i++) {
      expect((await call('POST', 'p/uploads/o/finalize')).statusCode, 200);
    }
    expect(
      (await call('POST', 'p/uploads', json: metadata().toJson())).statusCode,
      200,
    );
    expect(
      (await call('PUT', 'p/uploads/o/content', body: bytes)).statusCode,
      200,
    );
    final download = await call('GET', 'p/originals/o/content');
    expect(await download.read().expand((c) => c).toList(), bytes);
    expect(download.headers['x-content-sha256'], digest(bytes));
    final part = await call(
      'GET',
      'p/originals/o/content',
      headers: {'range': 'bytes=0-4'},
    );
    expect(part.statusCode, 206);
    expect(await part.readAsString(), '%PDF-');
    expect(
      (await call(
        'GET',
        'p/originals/o/content',
        headers: {'range': 'bytes=999-'},
      )).statusCode,
      416,
    );
    expect(
      (await call('GET', 'p/originals/o/content', token: 'b-token')).statusCode,
      404,
    );
    expect(
      (await call('POST', 'q/uploads', json: metadata().toJson())).statusCode,
      404,
    );
    expect(
      (await call('GET', 'p/originals/o/content', token: 'wrong')).statusCode,
      401,
    );
    expect(
      (await call(
        'GET',
        'p/originals/o/content',
        headers: {'origin': 'http://untrusted.test'},
      )).statusCode,
      403,
    );
    final quota = (await db.execute(
      "SELECT used_bytes,reserved_bytes FROM accounts WHERE owner_id='a'",
    )).single;
    expect(quota[0], bytes.length);
    expect(quota[1], 0);
    expect((await db.execute('SELECT * FROM document_outbox')), hasLength(1));
  });
  test(
    'lost object-write response is reconciled after metadata rollback',
    () async {
      await staged();
      objects.losePublishResponse = true;
      expect((await call('POST', 'p/uploads/o/finalize')).statusCode, 503);
      expect(objects.data[store.originalKey('a', 'o')], bytes);
      expect((await db.execute('SELECT * FROM document_outbox')), isEmpty);
      expect((await call('POST', 'p/uploads/o/finalize')).statusCode, 200);
      expect((await db.execute('SELECT * FROM document_outbox')), hasLength(1));
      expect(
        (await db.execute(
          "SELECT used_bytes,reserved_bytes FROM accounts WHERE owner_id='a'",
        )).single.toList(),
        [bytes.length, 0],
      );
    },
  );
  test(
    'staging replacement and corrupt published bytes are never accepted',
    () async {
      await staged();
      objects.data[store.stagingKey('a', 'o')] = Uint8List.fromList([0, 1, 2]);
      expect((await call('POST', 'p/uploads/o/finalize')).statusCode, 422);
      expect((await db.execute('SELECT * FROM document_outbox')), isEmpty);
      await store.stage('a', 'p', 'o', bytes);
      await store.finalize('a', 'p', 'o');
      objects.data[store.originalKey('a', 'o')] = Uint8List.fromList([0]);
      expect((await call('GET', 'p/originals/o/content')).statusCode, 422);
    },
  );
  test('a changed idempotent command and concurrent quota reservations cannot double-spend', () async {
    await db.execute(
      "UPDATE accounts SET quota_bytes=${bytes.length} WHERE owner_id='a'",
    );
    final results = await Future.wait([
      for (final id in ['one', 'two'])
        call('POST', 'p/uploads', json: metadata(id: id).toJson()),
    ]);
    expect(results.map((r) => r.statusCode).toList()..sort(), [200, 409]);
    final winner =
        (await db.execute('SELECT original_id FROM uploads')).single[0]
            as String;
    final altered = {
      ...metadata(id: winner).toJson(),
      'fileName': 'changed.pdf',
    };
    expect((await call('POST', 'p/uploads', json: altered)).statusCode, 409);
    expect(
      (await db.execute(
        "SELECT reserved_bytes FROM accounts WHERE owner_id='a'",
      )).single[0],
      bytes.length,
    );
  });
  test('expiry releases reservation, supports renewal and recovers a published orphan', () async {
    await staged();
    await db.execute("UPDATE uploads SET expires_at='2020-01-01T00:00:00Z'");
    await store.cleanup();
    expect(
      (await db.execute(
        "SELECT reserved_bytes FROM accounts WHERE owner_id='a'",
      )).single[0],
      0,
    );
    await staged();
    objects.losePublishResponse = true;
    expect((await call('POST', 'p/uploads/o/finalize')).statusCode, 503);
    await db.execute("UPDATE uploads SET expires_at='2020-01-01T00:00:00Z'");
    await store.cleanup();
    await store.cleanup();
    expect((await db.execute('SELECT state FROM uploads')).single[0], 'ready');
    expect((await db.execute('SELECT * FROM document_outbox')), hasLength(1));
    expect(objects.data.containsKey(store.stagingKey('a', 'o')), isFalse);
  });
  test(
    'revoking cloud writes preserves existing read access and stored bytes',
    () async {
      await staged();
      await store.finalize('a', 'p', 'o');
      await db.execute(
        "UPDATE profile_access SET cloud_enabled=false WHERE owner_id='a'",
      );
      expect(
        (await call(
          'POST',
          'p/uploads',
          json: metadata(id: 'other').toJson(),
        )).statusCode,
        403,
      );
      expect((await call('GET', 'p/originals/o/content')).statusCode, 200);
      await db.execute("DELETE FROM profile_access WHERE owner_id='a'");
      expect((await call('GET', 'p/originals/o/content')).statusCode, 404);
    },
  );
}
