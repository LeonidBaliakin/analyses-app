import 'package:medical_domain/medical_domain.dart';

/// Presentation data. Medical identity and compatibility are resolved upstream.
final class HistoryPoint {
  const HistoryPoint({
    required this.date,
    required this.value,
    this.unit = '',
    this.reference = '',
    this.source = '',
    this.status = '',
    this.details = '',
  });
  final CalendarDate date;
  final String value, unit, reference, source, status, details;
}

final class HistoryRow {
  const HistoryRow({
    required this.id,
    required this.name,
    required this.group,
    required this.points,
    this.context = '',
  });
  final String id, name, group, context;
  final List<HistoryPoint> points;
}

enum HistoryEventKind { medication, illness, complaint, measurement }

final class HistoryEvent {
  const HistoryEvent({
    required this.id,
    required this.name,
    required this.start,
    required this.kind,
    this.end,
    this.detail = '',
  });
  final String id, name, detail;
  final CalendarDate start;
  final CalendarDate? end;
  final HistoryEventKind kind;
}

final class HistoryData {
  const HistoryData({
    required this.rows,
    this.events = const [],
    this.isDemo = false,
  });
  final List<HistoryRow> rows;
  final List<HistoryEvent> events;
  final bool isDemo;
}

DateTime historyDate(CalendarDate date) =>
    DateTime.utc(date.year, date.month, date.day);
