import 'calendar_date.dart';
import 'health_records.dart';

final class ReportPeriod {
  ReportPeriod(this.start, this.end) {
    if (start.compareTo(end) > 0) throw const InvalidRecord('period');
  }
  final CalendarDate start, end;
  bool includes(CalendarDate date) =>
      date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
  bool overlaps(MedicationCourse course) =>
      course.start.compareTo(end) <= 0 &&
      (course.end == null || course.end!.compareTo(start) >= 0);
}

final class ResultSeries {
  ResultSeries(List<LabResult> values) : results = List.unmodifiable(values);
  final List<LabResult> results;
  LabResult get latest => results.first;
  List<LabResult> get latestOnDate =>
      List.unmodifiable(results.where((r) => r.date == latest.date));
  LabResult? get previous {
    if (latestOnDate.length != 1) return null;
    final previous = results
        .where((r) => r.date.compareTo(latest.date) < 0)
        .firstOrNull;
    if (previous == null ||
        results.where((r) => r.date == previous.date).length != 1) {
      return null;
    }
    return previous;
  }
}

final class HealthReport {
  HealthReport._(
    this.profile,
    this.period,
    List<LabResult> results,
    List<MedicationCourse> medications,
    List<HomeMeasurement> measurements,
    List<ResultSeries> series,
  ) : results = List.unmodifiable(results),
      medications = List.unmodifiable(medications),
      measurements = List.unmodifiable(measurements),
      series = List.unmodifiable(series);
  final MedicalProfile? profile;
  final ReportPeriod period;
  final List<LabResult> results;
  final List<MedicationCourse> medications;
  final List<HomeMeasurement> measurements;
  final List<ResultSeries> series;
  factory HealthReport.build(
    Iterable<RecordEntry> input,
    String profileId,
    ReportPeriod period,
  ) {
    final records = input
        .where((e) => !e.deleted && e.record.profileId == profileId)
        .map((e) => e.record)
        .toList();
    final results =
        records
            .whereType<LabResult>()
            .where((r) => period.includes(r.date))
            .toList()
          ..sort((a, b) {
            final d = b.date.compareTo(a.date);
            return d == 0 ? a.id.compareTo(b.id) : d;
          });
    final meds =
        records.whereType<MedicationCourse>().where(period.overlaps).toList()
          ..sort((a, b) {
            final d = a.start.compareTo(b.start);
            return d == 0 ? a.id.compareTo(b.id) : d;
          });
    final measurements =
        records
            .whereType<HomeMeasurement>()
            .where((r) => period.includes(r.date))
            .toList()
          ..sort((a, b) {
            final d = b.date.compareTo(a.date);
            return d == 0 ? a.id.compareTo(b.id) : d;
          });
    final groups = <String, List<LabResult>>{};
    for (final r in results) {
      final c = r.coding;
      // Unknown/unconfirmed identity or unit never merges records by display name.
      final key =
          c == null ||
              c.unitId == null ||
              [r.laboratory, r.specimen, r.method].any((v) => v.trim().isEmpty)
          ? 'record:${r.id}'
          : [
              c.terminologyReleaseId,
              c.indicatorId,
              c.unitId!,
              r.laboratory,
              r.specimen,
              r.method,
            ].map((v) => '${v.length}:$v').join('|');
      groups.putIfAbsent(key, () => []).add(r);
    }
    return HealthReport._(
      records.whereType<MedicalProfile>().firstOrNull,
      period,
      results,
      meds,
      measurements,
      groups.values.map(ResultSeries.new).toList(),
    );
  }
}
