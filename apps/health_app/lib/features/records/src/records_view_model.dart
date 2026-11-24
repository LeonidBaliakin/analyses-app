import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

enum RecordsError { load, save, conflict, invalid }

/// UI state and commands; the repository owns durable records and transactions.
final class RecordsViewModel extends ChangeNotifier {
  RecordsViewModel({
    required HealthRecordsRepository repository,
    required this.newId,
    required this.clock,
    TerminologyCatalog? terminology,
  }) : _records = HealthRecords(repository),
       terminology = terminology ?? bundledTerminology;
  static const profileId = 'local-profile';
  final HealthRecords _records;
  final TerminologyCatalog terminology;
  final String Function() newId;
  final DateTime Function() clock;
  List<RecordEntry> _entries = const [];
  List<RecordEntry> get entries => _entries;
  bool loading = false, saving = false, loaded = false, _disposed = false;
  RecordsError? error;
  RecordEntry? get profile =>
      _entries.where((e) => e.record is MedicalProfile).firstOrNull;
  List<RecordEntry> ofKind(RecordKind kind) =>
      _entries.where((e) => e.record.kind == kind).toList(growable: false);
  CalendarDate get today {
    final now = clock();
    return CalendarDate(now.year, now.month, now.day);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (loading || saving) return;
    loading = true;
    error = null;
    _notify();
    try {
      _entries = List.unmodifiable(await _records.repository.read(profileId));
      loaded = true;
    } catch (_) {
      error = RecordsError.load;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> save(RecordMutation mutation) async {
    if (saving || loading || !loaded) return false;
    saving = true;
    error = null;
    _notify();
    try {
      await _records.save(mutation);
      _entries = List.unmodifiable(await _records.repository.read(profileId));
      return true;
    } on RecordConflict {
      error = RecordsError.conflict;
      return false;
    } on InvalidRecord {
      error = RecordsError.invalid;
      return false;
    } catch (_) {
      error = RecordsError.save;
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<List<RecordEntry>> history(String id) =>
      _records.repository.history(profileId, id);

  @override
  void dispose() {
    _disposed = true;
    unawaited(_records.repository.close().catchError((Object _) {}));
    super.dispose();
  }
}
