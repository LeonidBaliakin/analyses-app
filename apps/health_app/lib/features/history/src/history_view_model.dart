import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';

import 'history_models.dart';

enum HistoryPeriod { latest, recent, all, custom }

final class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._data, {required this.today, ReportPeriod? period})
    : _period = period {
    if (period != null) periodKind = HistoryPeriod.custom;
  }
  HistoryData _data;
  HistoryData get data => _data;
  final CalendarDate today;
  ReportPeriod? _period;
  HistoryPeriod periodKind = HistoryPeriod.all;
  bool invalidPeriod = false, showEvents = false;
  String query = '';
  String? group;
  final Set<String> _selected = {};
  List<CalendarDate>? _dates;
  Set<String> get selected => Set.unmodifiable(_selected);
  List<CalendarDate> get allDates => _dates ??=
      (_data.rows.expand((r) => r.points).map((p) => p.date).toSet().toList()
        ..sort());
  ReportPeriod get period =>
      _period ??
      ReportPeriod(allDates.firstOrNull ?? today, allDates.lastOrNull ?? today);
  List<CalendarDate> get dates => allDates.where(period.includes).toList();
  List<String> get groups => _data.rows.map((r) => r.group).toSet().toList();
  List<HistoryRow> get suggestions {
    final words = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return _data.rows
        .where(
          (r) => words.every(
            '${r.name} ${r.context} ${r.group}'.toLowerCase().contains,
          ),
        )
        .toList();
  }

  List<HistoryRow> get rows => _data.rows
      .where(
        (r) =>
            (group == null || r.group == group) &&
            (_selected.isEmpty || _selected.contains(r.id)) &&
            r.points.any((p) => period.includes(p.date)),
      )
      .toList();
  List<HistoryEvent> get events =>
      (_data.events
          .where(
            (e) =>
                e.start.compareTo(period.end) <= 0 &&
                (e.end == null
                    ? e.kind == HistoryEventKind.medication ||
                          period.includes(e.start)
                    : e.end!.compareTo(period.start) >= 0),
          )
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start)));
  List<HistoryPoint> points(HistoryRow row, CalendarDate date) =>
      row.points.where((p) => p.date == date).toList();
  void updateData(HistoryData value) {
    _data = value;
    _dates = null;
    // An update must not widen an explicitly selected report to all records
    // when the selected record disappears. Reset remains an explicit action.
    if (!groups.contains(group)) group = null;
    if (periodKind != HistoryPeriod.custom) _selectPeriod(periodKind);
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void select(String id) {
    if (!_data.rows.any((r) => r.id == id)) return;
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void selectGroup(String? value) {
    group = value;
    notifyListeners();
  }

  void toggleEvents() {
    showEvents = !showEvents;
    notifyListeners();
  }

  void _selectPeriod(HistoryPeriod value) {
    final values = allDates;
    periodKind = value;
    invalidPeriod = false;
    _period = values.isEmpty || value == HistoryPeriod.all
        ? null
        : ReportPeriod(
            value == HistoryPeriod.latest
                ? values.last
                : values[values.length > 1 ? values.length - 2 : 0],
            values.last,
          );
  }

  void selectPeriod(HistoryPeriod value) {
    if (value == HistoryPeriod.custom) return;
    _selectPeriod(value);
    notifyListeners();
  }

  void setPeriod(String start, String end) {
    try {
      _period = ReportPeriod(
        CalendarDate.parse(start),
        CalendarDate.parse(end),
      );
      periodKind = HistoryPeriod.custom;
      invalidPeriod = false;
    } on Exception {
      invalidPeriod = true;
    }
    notifyListeners();
  }

  void reset() {
    _selected.clear();
    group = null;
    query = '';
    _selectPeriod(HistoryPeriod.all);
    notifyListeners();
  }
}
