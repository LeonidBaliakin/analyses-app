import 'dart:convert';

import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:drift/drift.dart';
import 'package:medical_domain/medical_domain.dart';

mixin DraftStorage on GeneratedDatabase implements DraftRepository {
  DateTime get draftNow => DateTime.now();
  static const schema = [
    '''CREATE TABLE processing_jobs (job_id TEXT PRIMARY KEY, profile_id TEXT NOT NULL,original_id TEXT NOT NULL,
    request TEXT NOT NULL,status TEXT NOT NULL,error_code TEXT,artifact TEXT,updated_at TEXT NOT NULL)''',
    '''CREATE TABLE processing_drafts (job_id TEXT PRIMARY KEY,profile_id TEXT NOT NULL,original_id TEXT NOT NULL,
    revision INTEGER NOT NULL,payload TEXT NOT NULL,confirmed INTEGER NOT NULL DEFAULT 0)''',
    '''CREATE TABLE draft_history (job_id TEXT NOT NULL,revision INTEGER NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(job_id,revision))''',
    '''CREATE TABLE draft_confirmations (operation_id TEXT PRIMARY KEY,job_id TEXT NOT NULL,request TEXT NOT NULL,record_ids TEXT NOT NULL)''',
    '''CREATE TABLE confirmed_originals (profile_id TEXT NOT NULL,original_id TEXT NOT NULL,job_id TEXT NOT NULL,
    PRIMARY KEY(profile_id,original_id))''',
  ];

  Map<String, Object?> _original(OriginalDocument o) => {
    'documentId': o.documentId,
    'originalId': o.originalId,
    'profileId': o.profileId,
    'fileName': o.fileName,
    'mime': o.mime,
    'size': o.size,
    'sha256': o.sha256,
    'importedAt': o.importedAt.toIso8601String(),
    'importSource': o.importSource,
  };
  Map<String, Object?> _request(ProcessingJob j) => {
    'original': _original(j.original),
    'mode': j.mode.name,
    'terminologyReleaseId': j.terminologyReleaseId,
    'runtimeId': j.runtimeId,
  };
  ProcessingJob _job(QueryRow row) {
    final j = jsonDecode(row.read<String>('request')) as Map<String, dynamic>,
        o = j['original'] as Map;
    return ProcessingJob(
      id: row.read<String>('job_id'),
      original: OriginalDocument(
        documentId: o['documentId'] as String,
        originalId: o['originalId'] as String,
        profileId: o['profileId'] as String,
        fileName: o['fileName'] as String,
        mime: o['mime'] as String,
        size: o['size'] as int,
        sha256: o['sha256'] as String,
        importedAt: DateTime.parse(o['importedAt'] as String),
        importSource: o['importSource'] as String,
      ),
      mode: ProcessingMode.values.byName(j['mode'] as String),
      terminologyReleaseId: j['terminologyReleaseId'] as String,
      runtimeId: j['runtimeId'] as String,
      status: ProcessingStatus.values.byName(row.read<String>('status')),
      error: row.readNullable<String>('error_code'),
      updatedAt: DateTime.parse(row.read<String>('updated_at')),
      artifact: row.readNullable<String>('artifact') == null
          ? null
          : jsonDecode(row.read<String>('artifact')) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createProcessingJob(ProcessingJob job) async {
    job.original.validate();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(job.id) ||
        job.runtimeId.isEmpty ||
        job.terminologyReleaseId.isEmpty) {
      throw const ProcessingFailure('request');
    }
    final request = jsonEncode(_request(job));
    await transaction(() async {
      final original = await customSelect(
        'SELECT document_id,sha256,byte_size FROM originals WHERE profile_id=? AND original_id=?',
        variables: [
          Variable(job.original.profileId),
          Variable(job.original.originalId),
        ],
      ).getSingleOrNull();
      if (original == null ||
          original.read<String>('document_id') != job.original.documentId ||
          original.read<String>('sha256') != job.original.sha256 ||
          original.read<int>('byte_size') != job.original.size) {
        throw const ProcessingFailure('original');
      }
      final existing = await customSelect(
        'SELECT request FROM processing_jobs WHERE job_id=?',
        variables: [Variable(job.id)],
      ).getSingleOrNull();
      if (existing != null) {
        if (existing.read<String>('request') != request) {
          throw const OperationMismatch();
        }
        return;
      }
      await customStatement(
        'INSERT INTO processing_jobs(job_id,profile_id,original_id,request,status,updated_at) VALUES(?,?,?,?,?,?)',
        [
          job.id,
          job.original.profileId,
          job.original.originalId,
          request,
          ProcessingStatus.queued.name,
          draftNow.toUtc().toIso8601String(),
        ],
      );
    });
  }

  @override
  Future<List<ProcessingJob>> processingJobs(
    String profileId,
    String originalId,
  ) async => (await customSelect(
    'SELECT * FROM processing_jobs WHERE profile_id=? AND original_id=? ORDER BY updated_at DESC,job_id',
    variables: [Variable(profileId), Variable(originalId)],
  ).get()).map(_job).toList();
  @override
  Future<void> setProcessingStatus(
    String profileId,
    String jobId,
    ProcessingStatus status, {
    String? error,
    Map<String, dynamic>? artifact,
  }) async {
    await customStatement(
      "UPDATE processing_jobs SET status=?,error_code=?,artifact=COALESCE(?,artifact),updated_at=? WHERE profile_id=? AND job_id=? AND status NOT IN ('confirmed','cancelled','ready')",
      [
        status.name,
        error,
        artifact == null ? null : jsonEncode(artifact),
        draftNow.toUtc().toIso8601String(),
        profileId,
        jobId,
      ],
    );
  }

  @override
  Future<ProcessingDraft?> readDraft(String profileId, String jobId) async {
    final row = await customSelect(
      'SELECT payload FROM processing_drafts WHERE profile_id=? AND job_id=?',
      variables: [Variable(profileId), Variable(jobId)],
    ).getSingleOrNull();
    return row == null
        ? null
        : decodeDraft(
            jsonDecode(row.read<String>('payload')) as Map<String, dynamic>,
          );
  }

  @override
  Future<ProcessingDraft> storeGeneratedDraft(
    ProcessingDraft draft,
  ) => transaction(() async {
    final jobs = await processingJobs(draft.profileId, draft.originalId);
    final job = jobs.where((j) => j.id == draft.jobId).firstOrNull;
    if (job == null ||
        job.status == ProcessingStatus.cancelled ||
        job.mode != draft.mode ||
        job.original.sha256 != draft.originalSha256 ||
        job.original.documentId != draft.documentId ||
        job.terminologyReleaseId != draft.terminologyReleaseId) {
      throw const ProcessingFailure('job');
    }
    final existing = await readDraft(draft.profileId, draft.jobId);
    if (existing != null) {
      return existing; // Never overwrite review edits on a repeated delivery.
    }
    if (draft.revision != 1 || draft.confirmed) {
      throw const ProcessingFailure('draft');
    }
    final payload = jsonEncode(encodeDraft(draft));
    await customStatement('INSERT INTO processing_drafts VALUES(?,?,?,?,?,0)', [
      draft.jobId,
      draft.profileId,
      draft.originalId,
      1,
      payload,
    ]);
    await customStatement('INSERT INTO draft_history VALUES(?,?,?)', [
      draft.jobId,
      1,
      payload,
    ]);
    await customStatement(
      "UPDATE processing_jobs SET status='ready',updated_at=? WHERE job_id=?",
      [draftNow.toUtc().toIso8601String(), draft.jobId],
    );
    return draft;
  });

  String _immutable(ProcessingDraft d) => jsonEncode({
    ...encodeDraft(d),
    'rows': const <Object>[],
    'revision': 0,
    'confirmed': false,
  });
  bool _sourcesMatch(ProcessingDraft old, ProcessingDraft next) {
    if (next.rows.length < old.rows.length ||
        next.rows.length > 20 ||
        next.rows.map((r) => r.id).toSet().length != next.rows.length) {
      return false;
    }
    final before = encodeDraft(old)['rows'] as List,
        after = encodeDraft(next)['rows'] as List;
    for (var i = 0; i < old.rows.length; i++) {
      if (old.rows[i].id != next.rows[i].id ||
          jsonEncode(before[i]['source']) != jsonEncode(after[i]['source'])) {
        return false;
      }
    }
    return next.rows
        .skip(old.rows.length)
        .every((r) => r.id.startsWith('manual-') && r.source.isEmpty);
  }

  @override
  Future<ProcessingDraft> saveDraft(
    ProcessingDraft draft,
    int expectedRevision,
  ) => transaction(() async {
    final old = await readDraft(draft.profileId, draft.jobId);
    if (old == null ||
        old.confirmed ||
        _immutable(old) != _immutable(draft) ||
        !_sourcesMatch(old, draft)) {
      throw const ProcessingFailure('draft');
    }
    if (old.revision == expectedRevision + 1 &&
        jsonEncode(encodeDraft(old)) ==
            jsonEncode(
              encodeDraft(draft.edited(draft.rows, revision: old.revision)),
            )) {
      return old;
    }
    if (old.revision != expectedRevision) throw const RecordConflict();
    final updated = draft.edited(draft.rows, revision: expectedRevision + 1);
    final payload = jsonEncode(encodeDraft(updated));
    await customStatement(
      'UPDATE processing_drafts SET payload=?,revision=? WHERE job_id=?',
      [payload, updated.revision, draft.jobId],
    );
    await customStatement('INSERT INTO draft_history VALUES(?,?,?)', [
      draft.jobId,
      updated.revision,
      payload,
    ]);
    return updated;
  });
  @override
  Future<List<String>> confirmDraft(
    ProcessingDraft draft,
    String operationId,
    int expectedRevision,
  ) => transaction(() async {
    if (operationId.isEmpty) throw const ProcessingFailure('operation');
    final request = jsonEncode({
      'draft': encodeDraft(draft),
      'expectedRevision': expectedRevision,
    });
    final previous = await customSelect(
      'SELECT request,record_ids FROM draft_confirmations WHERE operation_id=?',
      variables: [Variable(operationId)],
    ).getSingleOrNull();
    if (previous != null) {
      if (previous.read<String>('request') != request) {
        throw const OperationMismatch();
      }
      return List<String>.from(
        jsonDecode(previous.read<String>('record_ids')) as List,
      );
    }
    final old = await readDraft(draft.profileId, draft.jobId);
    if (old == null ||
        old.confirmed ||
        old.revision != expectedRevision ||
        jsonEncode(encodeDraft(old)) != jsonEncode(encodeDraft(draft))) {
      throw const RecordConflict();
    }
    final source = await customSelect(
      'SELECT sha256,document_id FROM originals WHERE profile_id=? AND original_id=?',
      variables: [Variable(draft.profileId), Variable(draft.originalId)],
    ).getSingleOrNull();
    if (source == null ||
        source.read<String>('sha256') != draft.originalSha256 ||
        source.read<String>('document_id') != draft.documentId) {
      throw const ProcessingFailure('original');
    }
    final confirmed = await customSelect(
      'SELECT job_id FROM confirmed_originals WHERE profile_id=? AND original_id=?',
      variables: [Variable(draft.profileId), Variable(draft.originalId)],
    ).getSingleOrNull();
    if (confirmed != null) throw const ProcessingFailure('already_confirmed');
    final results = confirmedResults(draft);
    for (final result in results) {
      await (this as HealthRecordsRepository).commit(
        RecordMutation(
          operationId: '$operationId:${result.id}',
          record: result,
          expectedRevision: 0,
        ),
      );
    }
    final ids = results.map((r) => r.id).toList();
    await customStatement('INSERT INTO draft_confirmations VALUES(?,?,?,?)', [
      operationId,
      draft.jobId,
      request,
      jsonEncode(ids),
    ]);
    await customStatement('INSERT INTO confirmed_originals VALUES(?,?,?)', [
      draft.profileId,
      draft.originalId,
      draft.jobId,
    ]);
    final updated = draft.edited(
      draft.rows,
      revision: draft.revision + 1,
      confirmed: true,
    );
    final payload = jsonEncode(encodeDraft(updated));
    await customStatement(
      'UPDATE processing_drafts SET payload=?,revision=?,confirmed=1 WHERE job_id=?',
      [payload, updated.revision, draft.jobId],
    );
    await customStatement('INSERT INTO draft_history VALUES(?,?,?)', [
      draft.jobId,
      updated.revision,
      payload,
    ]);
    await customStatement(
      "UPDATE processing_jobs SET status='confirmed' WHERE job_id=?",
      [draft.jobId],
    );
    return ids;
  });
}
