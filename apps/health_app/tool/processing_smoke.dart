// Only generated synthetic fixtures. The real adapters and shared confirmation path.
import 'dart:convert';
import 'dart:io';

import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:drift/native.dart';
import 'package:health_app/data/documents/documents_http_gateway.dart';
import 'package:health_app/data/processing/local_engine_io.dart';
import 'package:health_app/data/processing/remote_engine.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

void check(bool condition, String name) {
  if (!condition) throw StateError(name);
}

Future<void> main() async {
  final env = {
    for (final line in await File('../../infra/documents/.env').readAsLines())
      line.split('=').first: line.substring(line.indexOf('=') + 1),
  };
  final endpoint = Uri.parse('http://127.0.0.1:18088/');
  final gateway = DocumentsHttpGateway(
    endpoint: endpoint,
    token: env['DOCUMENTS_DEV_TOKEN']!,
  );
  final local = LocalProcessingEngine(
    File('../../.runtime/processing/local-config.json').absolute.path,
  );
  final remote = RemoteProcessingEngine(
    endpoint: endpoint,
    token: env['DOCUMENTS_DEV_TOKEN']!,
    profileId: 'local-profile',
  );
  final temp = await Directory.systemTemp.createTemp(
    'analyses-processing-smoke-',
  );
  final file = File('${temp.path}/records.sqlite');
  var db = RecordsDatabase(NativeDatabase(file));
  try {
    await db.commit(
      const RecordMutation(
        operationId: 'profile',
        record: MedicalProfile(
          id: 'local-profile',
          name: 'Synthetic processing smoke',
        ),
        expectedRevision: 0,
      ),
    );
    final bytes = await File(
      '../../.runtime/processing/fixtures/ru-numeric.png',
    ).readAsBytes();
    var expectedRecords = 0;
    for (final mode in ProcessingMode.values) {
      final engine = mode == ProcessingMode.local ? local : remote;
      final runtime = await engine.runtimeId();
      check(runtime != null, 'runtime unavailable');
      final id =
          'processing-smoke-${mode.name}-${originalSha256(bytes).substring(0, 12)}';
      final o = OriginalDocument(
        documentId: 'doc-$id',
        originalId: id,
        profileId: 'local-profile',
        fileName: 'synthetic.png',
        mime: 'image/png',
        size: bytes.length,
        sha256: originalSha256(bytes),
        importedAt: DateTime.utc(2026, 11, 24),
        importSource: 'files',
      );
      await db.importOriginal(o, bytes);
      if (mode == ProcessingMode.ownServer) await gateway.upload(o, bytes);
      final job = ProcessingJob(
        id: 'job-${mode.name}-${DateTime.now().microsecondsSinceEpoch}',
        original: o,
        mode: mode,
        terminologyReleaseId: bundledTerminology.active.id,
        runtimeId: runtime!,
      );
      await db.createProcessingJob(job);
      final raw = await engine.run(
        job,
        bytes,
        Cancellation(),
        (s, a) => db.setProcessingStatus(o.profileId, job.id, s, artifact: a),
      );
      var draft = await db.storeGeneratedDraft(
        decodeGeneratedDraft(raw, job, bundledTerminology.active),
      );
      check(draft.rows.length == 2, 'two synthetic rows expected');
      check(
        (await db.read(o.profileId))
                .where((r) => r.record is LabResult)
                .length ==
            expectedRecords,
        'draft must not create records',
      );
      final row = draft.rows.first;
      draft = await db.saveDraft(
        draft.edited([
          row.edit(
            {...row.review, 'value': '141'},
            coding: bundledTerminology.active.confirm(
              indicatorId: 'indicator.hemoglobin.blood',
              unitId: 'unit.g-per-l',
              sourceName: row.review['name']!,
              sourceUnit: row.review['unit']!,
              sourceLaboratory: row.review['laboratory']!,
              sourceSpecimen: row.review['specimen']!,
              sourceMethod: row.review['method']!,
            ),
          ),
          draft.rows.last,
        ]),
        1,
      );
      final before = encodeDraft(draft);
      await db.close();
      db = RecordsDatabase(NativeDatabase(file));
      draft = (await db.readDraft(o.profileId, job.id))!;
      check(
        jsonEncode(encodeDraft(draft)) == jsonEncode(before),
        'draft restart',
      );
      final ids = await db.confirmDraft(
        draft,
        'confirm-${job.id}',
        draft.revision,
      );
      check(
        jsonEncode(
              await db.confirmDraft(draft, 'confirm-${job.id}', draft.revision),
            ) ==
            jsonEncode(ids),
        'idempotent confirmation',
      );
      expectedRecords += 2;
      final results = (await db.read(o.profileId))
          .map((r) => r.record)
          .whereType<LabResult>()
          .where((r) => r.documentSource?.jobId == job.id)
          .toList();
      check(
        results
                    .firstWhere((r) => r.documentSource!.rowId == row.id)
                    .value
                    .raw ==
                '141' &&
            results
                    .firstWhere((r) => r.documentSource!.rowId == row.id)
                    .documentSource!
                    .fields['value'] ==
                '140',
        'source separated from correction',
      );
      check(
        results
                .firstWhere((r) => r.documentSource!.rowId != row.id)
                .value
                .raw ==
            '< 0,0100',
        'precision and comparison',
      );
      check(
        (await db.readOriginal(o.profileId, o.originalId)).length ==
            bytes.length,
        'original still present',
      );
      o.verify(await db.readOriginal(o.profileId, o.originalId));
      final second = ProcessingJob(
        id: 'repeat-${job.id}',
        original: o,
        mode: mode,
        terminologyReleaseId: job.terminologyReleaseId,
        runtimeId: job.runtimeId,
      );
      await db.createProcessingJob(second);
      final duplicate = await db.storeGeneratedDraft(
        decodeGeneratedDraft(raw, second, bundledTerminology.active),
      );
      try {
        await db.confirmDraft(duplicate, 'confirm-${second.id}', 1);
        throw StateError('duplicate original was confirmed');
      } on ProcessingFailure catch (e) {
        check(
          e.code == 'already_confirmed',
          'expected original confirmation guard',
        );
      }
      check(
        (await db.read(o.profileId))
                .where((r) => r.record is LabResult)
                .length ==
            expectedRecords,
        'no duplicate records',
      );
      stdout.writeln(
        '${mode.name}: real OCR + LLM → shared draft → edit/restart → confirmation/replay; original SHA-256 preserved',
      );
    }
  } finally {
    local.close();
    remote.close();
    gateway.close();
    await db.close();
    await temp.delete(recursive: true);
  }
}
