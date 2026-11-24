import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

final class ProcessingViewModel extends ChangeNotifier {
  ProcessingViewModel({
    required this.repository,
    required this.originals,
    required this.local,
    required this.server,
    required this.serverOriginalReady,
    required this.newId,
    required this.onConfirmed,
    TerminologyCatalog? terminology,
  }) : terminology = terminology ?? bundledTerminology;
  final DraftRepository repository;
  final OriginalRepository originals;
  final ProcessingEngine local;
  final ProcessingEngine? Function() server;
  final bool Function(OriginalDocument) serverOriginalReady;
  final String Function() newId;
  final Future<void> Function() onConfirmed;
  final TerminologyCatalog terminology;
  OriginalDocument? original;
  List<ProcessingJob> jobs = const [];
  ProcessingDraft? draft;
  ProcessingJob? activeJob;
  ProcessingEngine? _activeEngine;
  Cancellation? _cancel;
  bool running = false, saving = false, _disposed = false;
  String? error;
  ProcessingDraft? _pendingConfirmation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _refresh() async {
    final o = original;
    if (o == null) return;
    try {
      jobs = await repository.processingJobs(o.profileId, o.originalId);
    } catch (_) {
      error = 'load';
    }
  }

  Future<bool> open(OriginalDocument o) async {
    if (running && original?.originalId != o.originalId) {
      error = 'busy';
      _notify();
      return false;
    }
    original = o;
    error = null;
    await _refresh();
    if (!running) {
      _pendingConfirmation = null;
      draft = null;
      for (final job in jobs) {
        final d = await repository.readDraft(o.profileId, job.id);
        if (d != null) {
          draft = d;
          break;
        }
      }
    }
    _notify();
    return true;
  }

  Future<void> selectJob(ProcessingJob job) async {
    draft = await repository.readDraft(job.original.profileId, job.id);
    _pendingConfirmation = null;
    _notify();
  }

  Future<void> start(ProcessingMode mode) async {
    if (running || saving || original == null) return;
    final o = original!;
    if (mode == ProcessingMode.ownServer && !serverOriginalReady(o)) {
      error = 'upload_first';
      _notify();
      return;
    }
    final engine = mode == ProcessingMode.local ? local : server();
    if (engine == null) {
      error = 'unavailable';
      _notify();
      return;
    }
    running = true;
    error = null;
    _notify();
    try {
      final runtime = await engine.runtimeId();
      if (runtime == null) throw const ProcessingFailure('unavailable');
      final job = ProcessingJob(
        id: newId(),
        original: o,
        mode: mode,
        terminologyReleaseId: terminology.active.id,
        runtimeId: runtime,
      );
      await repository.createProcessingJob(job);
      await _execute(job, engine);
    } catch (e) {
      _error(e);
    } finally {
      running = false;
      await _refresh();
      _notify();
    }
  }

  Future<void> resume(ProcessingJob job) async {
    if (running || saving) return;
    final engine = job.mode == ProcessingMode.local ? local : server();
    if (engine == null) {
      error = 'unavailable';
      _notify();
      return;
    }
    running = true;
    error = null;
    _notify();
    try {
      if (await engine.runtimeId() != job.runtimeId) {
        throw const ProcessingFailure('runtime_changed');
      }
      await _execute(job, engine);
    } catch (e) {
      _error(e);
    } finally {
      running = false;
      await _refresh();
      _notify();
    }
  }

  void _error(Object e) {
    error = switch (e) {
      ProcessingFailure(:final code) => code,
      RecordConflict() => 'conflict',
      ProcessingCancelled() => 'cancelled',
      _ => 'failed',
    };
  }

  Future<void> _execute(ProcessingJob job, ProcessingEngine engine) async {
    activeJob = job;
    _activeEngine = engine;
    _cancel = Cancellation();
    _pendingConfirmation = null;
    try {
      final bytes = await originals.readOriginal(
        job.original.profileId,
        job.original.originalId,
      );
      final raw = await engine.run(job, bytes, _cancel!, (
        status,
        artifact,
      ) async {
        await repository.setProcessingStatus(
          job.original.profileId,
          job.id,
          status,
          artifact: artifact,
        );
        await _refresh();
        _notify();
      });
      _cancel!.check();
      final release = terminology.releases[job.terminologyReleaseId];
      if (release == null) throw const ProcessingFailure('terminology');
      draft = await repository.storeGeneratedDraft(
        decodeGeneratedDraft(raw, job, release),
      );
    } on ProcessingCancelled {
      await repository.setProcessingStatus(
        job.original.profileId,
        job.id,
        ProcessingStatus.cancelled,
      );
      rethrow;
    } catch (e) {
      await repository.setProcessingStatus(
        job.original.profileId,
        job.id,
        ProcessingStatus.failed,
        error: e is ProcessingFailure ? e.code : 'failed',
      );
      rethrow;
    } finally {
      activeJob = null;
      _activeEngine = null;
      _cancel = null;
    }
  }

  Future<void> cancel() async {
    final job = activeJob, engine = _activeEngine;
    if (job == null || engine == null) return;
    _cancel?.cancelled = true;
    await repository.setProcessingStatus(
      job.original.profileId,
      job.id,
      ProcessingStatus.cancelled,
    );
    try {
      await engine.cancel(job);
    } catch (_) {}
    await _refresh();
    _notify();
  }

  Future<void> manualFromOcr(ProcessingJob job) async {
    if (running || saving || job.artifact == null) return;
    try {
      final release = terminology.releases[job.terminologyReleaseId];
      if (release == null) throw const ProcessingFailure('terminology');
      final generated = decodeGeneratedDraft(
        {
          ...job.artifact!,
          'schemaVersion': 1,
          'runtimeId': job.runtimeId,
          'rows': <Object>[],
        },
        job,
        release,
      );
      draft = await repository.storeGeneratedDraft(
        generated.edited([
          DraftRow(
            id: 'manual-${newId()}',
            source: {},
            review: {for (final field in draftFields) field: ''},
            valueKind: ResultValueKind.missing,
          ),
        ]),
      );
      error = null;
      await _refresh();
      _notify();
    } catch (e) {
      _error(e);
      _notify();
    }
  }

  Future<bool> save(ProcessingDraft edited) async {
    if (saving || running) return false;
    saving = true;
    error = null;
    _notify();
    try {
      draft = await repository.saveDraft(edited, edited.revision);
      _pendingConfirmation = null;
      return true;
    } catch (e) {
      _error(e);
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> confirm(ProcessingDraft edited) async {
    if (saving || running) return false;
    saving = true;
    error = null;
    _notify();
    try {
      ProcessingDraft candidate;
      if (_pendingConfirmation != null &&
          jsonEncode(encodeDraft(_pendingConfirmation!.edited(edited.rows))) !=
              jsonEncode(encodeDraft(_pendingConfirmation!))) {
        final latest = await repository.readDraft(
          edited.profileId,
          edited.jobId,
        );
        if (latest?.confirmed == true) throw const RecordConflict();
        _pendingConfirmation = null;
      }
      if (_pendingConfirmation != null) {
        candidate = _pendingConfirmation!;
      } else {
        final current = draft;
        if (current == null) throw const ProcessingFailure('draft');
        candidate =
            jsonEncode(encodeDraft(current)) == jsonEncode(encodeDraft(edited))
            ? current
            : await repository.saveDraft(edited, edited.revision);
        draft = candidate;
      }
      confirmedResults(candidate);
      _pendingConfirmation = candidate;
      await repository.confirmDraft(
        candidate,
        'confirm-${candidate.jobId}-${candidate.revision}',
        candidate.revision,
      );
      draft = await repository.readDraft(candidate.profileId, candidate.jobId);
      _pendingConfirmation = null;
      await _refresh();
      await onConfirmed();
      return true;
    } catch (e) {
      _error(e);
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel?.cancelled = true;
    local.close();
    super.dispose();
  }
}
