import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../records/records.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    required this.records,
    required DateTime Function() clock,
    required this.export,
    this.canExport = true,
    this.copy,
  }) {
    final now = clock(),
        today = DateTime.utc(now.year, now.month, now.day),
        start = today.subtract(const Duration(days: 29));
    period = ReportPeriod(
      CalendarDate(start.year, start.month, start.day),
      CalendarDate(now.year, now.month, now.day),
    );
    records.addListener(_updated);
  }
  final bool canExport;
  final Future<void> Function(String)? copy;
  final RecordsViewModel records;
  final Future<bool> Function(String, String) export;
  late ReportPeriod period;
  bool invalid = false, exporting = false, _disposed = false;
  String? error;
  HealthReport get report =>
      HealthReport.build(records.entries, RecordsViewModel.profileId, period);
  void _updated() {
    if (!_disposed) notifyListeners();
  }

  void setPeriod(String start, String end) {
    try {
      period = ReportPeriod(CalendarDate.parse(start), CalendarDate.parse(end));
      invalid = false;
    } catch (_) {
      invalid = true;
    }
    _updated();
  }

  Future<bool> saveHtml(String html, {ReportPeriod? snapshotPeriod}) async {
    if (!canExport || invalid || exporting) return false;
    exporting = true;
    error = null;
    _updated();
    try {
      final selected = snapshotPeriod ?? period;
      return await export(
        'health-report-${selected.start}-${selected.end}.html',
        html,
      );
    } catch (_) {
      error = 'export';
      return false;
    } finally {
      exporting = false;
      _updated();
    }
  }

  Future<bool> copyText(String text) async {
    if (invalid || exporting || copy == null) return false;
    error = null;
    exporting = true;
    _updated();
    try {
      await copy!(text);
      return true;
    } catch (_) {
      error = 'copy';
      return false;
    } finally {
      exporting = false;
      _updated();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    records.removeListener(_updated);
    super.dispose();
  }
}
