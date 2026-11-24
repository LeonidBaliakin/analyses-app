import 'dart:convert';

import 'package:flutter/services.dart';

/// A read-only presentation fixture from the original synthetic HTML demo.
/// Its statuses are captured, not computed medical rules or confirmed records.
final class DemoCatalog {
  DemoCatalog._(
    this.systems,
    this.sections,
    this.dates,
    this.labs,
    this.counts,
    this.eventLabels,
    this.uploads,
    this.profileCards,
    this.profile,
    this.events,
    this.latestIds,
    this.olderIds,
  );

  static Future<DemoCatalog> load() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/demo/original_demo.json'),
    ) as Map<String, dynamic>;
    final summary = raw['summary'] as Map<String, dynamic>;
    return DemoCatalog._(
      (raw['groups'] as List<dynamic>)
          .map(
            (g) => DemoSystem.fromJson(
              g as Map<String, dynamic>,
              raw['iconKeys'] as List<dynamic>,
            ),
          )
          .toList(growable: false),
      (raw['sections'] as List<dynamic>)
          .map(
            (s) => List<int>.from(
              (s as Map<String, dynamic>)['g'] as List<dynamic>,
            ),
          )
          .toList(growable: false),
      List<String>.from(raw['dates'] as List<dynamic>),
      List<String>.from(raw['labs'] as List<dynamic>),
      (summary['counts'] as List<dynamic>)
          .map((c) => int.parse(c as String))
          .toList(growable: false),
      List<String>.from(summary['events'] as List<dynamic>),
      (raw['uploads'] as List<dynamic>)
          .map((r) => List<String>.from(r as List<dynamic>))
          .toList(growable: false),
      List<String>.from(
        (raw['extras'] as Map<String, dynamic>)['profileCards']
            as List<dynamic>,
      ),
      Map<String, dynamic>.from(raw['profile'] as Map<String, dynamic>),
      Map<String, dynamic>.from(raw['events'] as Map<String, dynamic>),
      _ids(raw['latest']),
      _ids(raw['older']),
    );
  }

  static Set<String> _ids(dynamic values) => (values as List<dynamic>).map((v) {
    final pair = v as List<dynamic>;
    return '${pair[0]}-${pair[1]}';
  }).toSet();
  final List<DemoSystem> systems;
  final List<List<int>> sections;
  final List<String> dates, labs, eventLabels, profileCards;
  final List<int> counts;
  final List<List<String>> uploads;
  final Map<String, dynamic> profile, events;
  final Set<String> latestIds, olderIds;
  Iterable<DemoResult> get results => systems.expand((s) => s.results);
  DemoResult result(String id) => results.firstWhere((r) => r.id == id);
}

final class DemoSystem {
  DemoSystem._(this.id, this.icon, this.results);
  factory DemoSystem.fromJson(Map<String, dynamic> value, List<dynamic> icons) {
    final id = value['gi'] as int;
    return DemoSystem._(
      id,
      icons[id] as String,
      (value['rows'] as List<dynamic>)
          .map((r) => DemoResult.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
  final int id;
  final String icon;
  final List<DemoResult> results;
}

final class DemoResult {
  DemoResult._(
    this.id,
    this.systemId,
    this.name,
    this.unit,
    this.reference,
    this.status,
    this.points,
  );
  factory DemoResult.fromJson(Map<String, dynamic> raw) => DemoResult._(
    '${raw['gi']}-${raw['ri']}',
    raw['gi'] as int,
    raw['n'] as String,
    raw['u'] as String,
    raw['ref'] as String,
    raw['st'] as String,
    (raw['pts'] as List<dynamic>)
        .map((p) => DemoPoint.fromJson(p as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String id, name, unit, reference, status;
  final int systemId;
  final List<DemoPoint> points;
  DemoPoint? get current => points.isEmpty ? null : points.last;
  DemoPoint? get previous =>
      points.length < 2 ? null : points[points.length - 2];
}

final class DemoPoint {
  DemoPoint._(this.visit, this.date, this.raw, this.value, this.status);
  factory DemoPoint.fromJson(Map<String, dynamic> raw) => DemoPoint._(
    raw['i'] as int,
    raw['d'] as String,
    raw['raw'] as String,
    (raw['val'] as num).toDouble(),
    raw['st'] as String,
  );
  final int visit;
  final String date, raw, status;
  final double value;
}
