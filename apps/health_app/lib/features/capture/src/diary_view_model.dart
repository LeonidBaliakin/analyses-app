import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';

enum DiaryKind { glucose, pressure, sleep }

String diarySource(DiaryKind kind) => 'orange-of-health:diary:${kind.name}';

final class DiaryViewModel extends ChangeNotifier {
  DiaryViewModel({
    required this.profileId,
    required CalendarDate today,
    required this.newId,
    required this.save,
    required this.names,
    required this.units,
    this.entries = const [],
  }) : date = today.toString();
  final String profileId;
  final String Function() newId;
  final Future<bool> Function(List<HealthRecord>, String) save;
  final Map<DiaryKind, List<String>> names, units;
  List<HomeMeasurement> entries;
  int generation = 0;
  DiaryKind kind = DiaryKind.glucose;
  String date, time = '', offset = '', first = '', second = '';
  bool saving = false, invalid = false, failed = false, _disposed = false;
  List<HealthRecord>? _pending;
  String? _operation;
  void changed() {
    _pending = null;
    _operation = null;
    invalid = false;
    failed = false;
    notifyListeners();
  }

  void select(DiaryKind value) {
    kind = value;
    first = '';
    second = '';
    changed();
  }

  Future<bool> submit() async {
    if (saving) return false;
    try {
      if (_pending == null) {
        final day = CalendarDate.parse(date);
        int? minute, zone;
        if (time.isNotEmpty || offset.isNotEmpty) {
          final t = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(time),
              z = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(offset);
          if (t == null ||
              z == null ||
              int.parse(t[1]!) > 23 ||
              int.parse(t[2]!) > 59 ||
              int.parse(z[3]!) > 59) {
            throw const InvalidRecord('time');
          }
          minute = int.parse(t[1]!) * 60 + int.parse(t[2]!);
          zone =
              (int.parse(z[2]!) * 60 + int.parse(z[3]!)) *
              (z[1] == '-' ? -1 : 1);
        }
        final values = [first, if (kind == DiaryKind.pressure) second];
        for (final v in values) {
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n == null ||
              !n.isFinite ||
              n < 0 ||
              (kind == DiaryKind.sleep && n > 24)) {
            throw const InvalidRecord('value');
          }
        }
        _pending = [
          for (final (i, value) in values.indexed)
            HomeMeasurement(
              id: newId(),
              profileId: profileId,
              name: names[kind]![i],
              date: day,
              value: SourceValue(value, ResultValueKind.numeric),
              unit: units[kind]![i],
              source: diarySource(kind),
              minuteOfDay: minute,
              utcOffsetMinutes: zone,
            ),
        ];
        for (final record in _pending!) {
          record.validate();
        }
      }
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
      final ok = await save(_pending!, _operation!);
      failed = !ok;
      if (ok) {
        entries = [...entries, ..._pending!.cast<HomeMeasurement>()];
        _pending = null;
        _operation = null;
        first = '';
        second = '';
        generation++;
      }
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
