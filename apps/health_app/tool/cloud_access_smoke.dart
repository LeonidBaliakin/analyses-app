// Local-only probe. All temporary policy changes are restored in finally.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:document_domain/document_domain.dart';
import 'package:health_app/data/sync/http_sync_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:uuid/uuid.dart';

void check(bool condition, String why) {
  if (!condition) throw StateError(why);
}

Future<void> main(List<String> args) async {
  final deployment = Directory(
    args.isEmpty ? '../../.runtime/server-check' : args.first,
  ).absolute;
  final env = {
    for (final l in await File('${deployment.path}/.env').readAsLines())
      l.split('=').first: l.substring(l.indexOf('=') + 1),
  };
  final identity =
      (jsonDecode(
            await File('${deployment.path}/.secrets/identities.json')
                .readAsString(),
          ) as List).first
          as Map;
  final token =
      (jsonDecode(
            await File('${deployment.path}/.secrets/bootstrap.json')
                .readAsString(),
          ) as Map)['client_token']
          as String;
  final owner = identity['ownerId'] as String,
      profile = identity['profileId'] as String;
  final endpoint = Uri.parse('http://127.0.0.1:${env['API_PORT']}/');
  final client = http.Client(),
      sync = HttpSyncGateway(
        endpoint: endpoint,
        token: token,
        profileId: profile,
      );
  final directory = await Directory.systemTemp.createTemp('cloud-quota-probe-');
  final db = RecordsDatabase(
    NativeDatabase(File('${directory.path}/records.sqlite')),
  );
  Future<Map<String, dynamic>> get(String action) async {
    final r = await client.get(
      endpoint.resolve('v1/profiles/$profile/$action'),
      headers: {'authorization': 'Bearer $token'},
    );
    check(r.statusCode == 200, 'GET $action');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> grant(Map<String, dynamic> policy) async {
    final current = (await get('cloud-access'))['policy'] as Map;
    final process = await Process.start('docker', [
      'compose',
      'exec',
      '-T',
      'entitlements',
      '/app/entitlements',
      '--grant',
    ], workingDirectory: deployment.path);
    final output = process.stdout.transform(utf8.decoder).join(),
        errors = process.stderr.drain<void>();
    process.stdin.write(
      jsonEncode({
        'ownerId': owner,
        'operationId': const Uuid().v4(),
        'baseRevision': current['revision'],
        'policy': policy,
      }),
    );
    await process.stdin.close();
    final text = await output;
    await errors;
    check(await process.exitCode == 0, 'admin policy update');
    return jsonDecode(text) as Map<String, dynamic>;
  }

  final before = Map<String, dynamic>.from(
    (await get('cloud-access'))['policy'] as Map,
  );
  try {
    final identity = await sync.identity();
    await db.bindSync(profile, 'synthetic:$owner', const Uuid().v4(), identity);
    await SyncRunner(db, sync, profile, DateTime.now).run(force: true);
    if (!(await db.read(profile)).any((e) => e.record is MedicalProfile)) {
      await db.commit(
        RecordMutation(
          operationId: const Uuid().v4(),
          record: MedicalProfile(
            id: profile,
            name: 'SYNTHETIC cloud quota probe',
          ),
          expectedRevision: 0,
        ),
      );
      await SyncRunner(db, sync, profile, DateTime.now).run(force: true);
    }
    final id = const Uuid().v4();
    await db.commit(
      RecordMutation(
        operationId: const Uuid().v4(),
        record: LabResult(
          id: id,
          profileId: profile,
          name: 'SYNTHETIC pending quota result',
          date: CalendarDate(2026, 11, 26),
          value: const SourceValue('0,0100', ResultValueKind.numeric),
          category: AnalysisCategory.blood,
        ),
        expectedRevision: 0,
      ),
    );
    await grant({
      ...before,
      'recordLimit': 0,
      'storageLimitBytes': 0,
      'processingMonthlyLimit': 0,
    });
    try {
      await SyncRunner(db, sync, profile, DateTime.now).run(force: true);
      throw StateError('record quota accepted');
    } on SyncFailure catch (e) {
      check(e.code == 'sync_quota_exceeded', 'quota error surfaced');
    }
    check(
      await db.pendingSyncCount(profile) == 1,
      'denied operation remains in durable outbox',
    );
    final bytes = Uint8List.fromList(
      utf8.encode('%PDF-1.7\nSYNTHETIC quota probe\n%%EOF'),
    );
    final original = const Uuid().v4();
    final metadata = {
      'documentId': 'd-$original',
      'originalId': original,
      'fileName': 'synthetic.pdf',
      'mime': 'application/pdf',
      'size': bytes.length,
      'sha256': originalSha256(bytes),
      'importSource': 'files',
      'importedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final denied = await client.post(
      endpoint.resolve('v1/profiles/$profile/uploads'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(metadata),
    );
    check(
      denied.statusCode == 409 &&
          (jsonDecode(denied.body) as Map)['error'] == 'quota_exceeded',
      'storage byte quota',
    );
    final after = await grant(before);
    await SyncRunner(db, sync, profile, DateTime.now).run(force: true);
    check(
      await db.pendingSyncCount(profile) == 0,
      'same queued operation succeeds after grant',
    );
    final reserve = await client.post(
      endpoint.resolve('v1/profiles/$profile/uploads'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(metadata),
    );
    check(reserve.statusCode == 200, 'restored storage rights');
    final staged = await client.put(
      endpoint.resolve('v1/profiles/$profile/uploads/$original/content'),
      headers: {'authorization': 'Bearer $token'},
      body: bytes,
    );
    check(staged.statusCode == 200, 'stage original');
    check(
      (await client.post(
            endpoint.resolve('v1/profiles/$profile/uploads/$original/finalize'),
            headers: {'authorization': 'Bearer $token'},
          )).statusCode ==
          200,
      'verified original',
    );
    final caps = await get('processing-capabilities');
    await grant({...after, 'processingMonthlyLimit': 0});
    final recognition = await client.post(
      endpoint.resolve('v1/profiles/$profile/processing-jobs'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'jobId': const Uuid().v4(),
        'originalId': original,
        'runtimeId': caps['runtimeId'],
        'terminologyReleaseId': 'pilot',
      }),
    );
    check(
      recognition.statusCode == 409 &&
          (jsonDecode(recognition.body) as Map)['error'] ==
              'processing_quota_exceeded',
      'recognition admission quota',
    );
    await grant({
      ...before,
      'syncEnabled': false,
      'storageEnabled': false,
      'processingEnabled': false,
    });
    check(
      (await sync.identity()).canWrite == false,
      'sync permission independent',
    );
    final download = await client.get(
      endpoint.resolve('v1/profiles/$profile/originals/$original/content'),
      headers: {'authorization': 'Bearer $token'},
    );
    check(
      download.statusCode == 200 &&
          originalSha256(download.bodyBytes) == originalSha256(bytes),
      'read preserves immutable original when writes disabled',
    );
    check(
      (await get('processing-capabilities'))['processingAllowed'] == false,
      'recognition right denied',
    );
    stdout.writeln(
      'Cloud quota probe passed: retained outbox, grant/retry, byte quota, recognition quota, independent rights and original SHA-256.',
    );
  } finally {
    await grant(before);
    sync.close();
    client.close();
    await db.close();
    await directory.delete(recursive: true);
  }
}
