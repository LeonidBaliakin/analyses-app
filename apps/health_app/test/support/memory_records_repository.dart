import 'dart:async';

import 'package:medical_domain/medical_domain.dart';

class MemoryRecordsRepository implements HealthRecordBatchRepository {
  final entries = <String, RecordEntry>{};
  final mutations = <RecordMutation>[];
  bool failRead = false, failWrite = false;
  Completer<void>? writeGate;
  bool closed = false;
  @override
  Future<List<RecordEntry>> read(String profileId) async {
    if (failRead) throw StateError('synthetic read failure');
    return entries.values
        .where((e) => e.record.profileId == profileId && !e.deleted)
        .toList();
  }

  @override
  Future<List<int>> commitBatch(List<RecordMutation> values) async {
    final previous = Map<String, RecordEntry>.of(entries),
        count = mutations.length;
    try {
      return [for (final value in values) await commit(value)];
    } catch (_) {
      entries
        ..clear()
        ..addAll(previous);
      mutations.removeRange(count, mutations.length);
      rethrow;
    }
  }

  @override
  Future<int> commit(RecordMutation mutation) async {
    await writeGate?.future;
    if (failWrite) throw StateError('synthetic write failure');
    if ((entries[mutation.record.id]?.revision ?? 0) !=
        mutation.expectedRevision) {
      throw const RecordConflict();
    }
    final revision = mutation.expectedRevision + 1;
    mutations.add(mutation);
    entries[mutation.record.id] = RecordEntry(
      mutation.record,
      revision,
      deleted: mutation.delete,
    );
    return revision;
  }

  @override
  Future<List<RecordEntry>> history(String profileId, String recordId) async =>
      entries.values
          .where(
            (e) => e.record.id == recordId && e.record.profileId == profileId,
          )
          .toList();
  @override
  Future<void> close() async {
    closed = true;
  }
}
