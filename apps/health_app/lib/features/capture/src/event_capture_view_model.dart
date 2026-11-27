import 'package:flutter/foundation.dart';
import 'package:document_processing/document_processing.dart';
import 'package:medical_domain/medical_domain.dart';

/// Transient review state. Only confirm calls the injected persistence command.
final class EventCaptureViewModel extends ChangeNotifier {
  EventCaptureViewModel({
    required this.profile,
    required this.today,
    required this.newId,
    required this.save,
    List<EventCaptureRow>? initialRows,
  }) : rows = initialRows;
  final MedicalProfile profile;
  final CalendarDate today;
  final String Function() newId;
  final Future<bool> Function(List<HealthRecord>, String) save;
  String story = '';
  List<EventCaptureRow>? rows;
  bool saving = false, invalid = false, failed = false, _disposed = false;
  String? _operation;
  void _changed() {
    _operation = null;
    invalid = false;
    failed = false;
    notifyListeners();
  }

  void review() {
    rows = const EventCaptureParser().parse(story, today: today, newId: newId);
    _changed();
  }

  void update(EventCaptureRow row) {
    rows = [
      for (final r in rows!)
        if (r.id == row.id) row else r,
    ];
    _changed();
  }

  void add(CapturedEventKind kind) {
    rows = [
      ...?rows,
      EventCaptureRow(
        id: newId(),
        kind: kind,
        source: '',
        start: 0,
        end: 0,
        fields: const {},
      ),
    ];
    _changed();
  }

  void remove(String id) {
    rows = rows!.where((r) => r.id != id).toList();
    _changed();
  }

  Future<bool> confirm() async {
    if (saving) return false;
    late List<HealthRecord> records;
    try {
      records = confirmedEventRecords(rows ?? [], profile);
    } catch (_) {
      invalid = true;
      notifyListeners();
      return false;
    }
    _operation ??= newId();
    saving = true;
    failed = false;
    notifyListeners();
    try {
      final ok = await save(records, _operation!);
      failed = !ok;
      return ok;
    } catch (_) {
      failed = true;
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
