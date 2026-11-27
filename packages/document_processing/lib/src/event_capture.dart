import 'package:medical_domain/medical_domain.dart';

enum CapturedEventKind {
  illness,
  medication,
  hospitalization,
  complaint,
  weight,
  allergy,
  travel,
}

/// Heuristic suggestions, never confirmed medical facts. Raw fragments and
/// positions remain attached after edits. No network or model is invoked.
final class EventCaptureRow {
  EventCaptureRow({
    required this.id,
    required this.kind,
    required this.source,
    required this.start,
    required this.end,
    required Map<String, String> fields,
    this.issue,
  }) : fields = Map.unmodifiable(fields);
  final String id, source;
  final int start, end;
  final CapturedEventKind kind;
  final Map<String, String> fields;
  final String? issue;
  EventCaptureRow edit({
    CapturedEventKind? kind,
    Map<String, String>? fields,
  }) => EventCaptureRow(
    id: id,
    kind: kind ?? this.kind,
    source: source,
    start: start,
    end: end,
    fields: fields ?? this.fields,
    issue: issue,
  );
}

final class EventCaptureParser {
  const EventCaptureParser();
  static const version = 'local-event-rules-1';
  List<EventCaptureRow> parse(
    String story, {
    required CalendarDate today,
    required String Function() newId,
  }) {
    final chunks = story.split(
      RegExp(
        r'[.!?](?=\s|$)|[;\n]|(?:,\s*|\s+и\s+|\s+затем\s+)(?=(?:с \d|приним|пропис|назнач|болел|забол|лежал|госпитал|был[аи]?\s))',
      ),
    );
    var offset = 0;
    final rows = <EventCaptureRow>[];
    for (final chunk in chunks) {
      final at = story.indexOf(chunk, offset);
      offset = at + chunk.length;
      final source = chunk.trim();
      if (source.isEmpty) continue;
      final lower = source.toLowerCase();
      final kind =
          RegExp(
            r'пропис|приним|назнач|антибиотик|таблет|лекарств|препарат|taking|prescrib|medicine',
          ).hasMatch(lower)
          ? CapturedEventKind.medication
          : RegExp(r'стационар|больниц|госпитал|hospital').hasMatch(lower)
          ? CapturedEventKind.hospitalization
          : RegExp(
              r'болел|перебол|забол|орви|грипп|простуд|illness|was ill|flu',
            ).hasMatch(lower)
          ? CapturedEventKind.illness
          : RegExp(r'аллерг|allerg').hasMatch(lower)
          ? CapturedEventKind.allergy
          : RegExp(r'санатор|поездк|был[аи]? в|ездил|travel|trip')
                .hasMatch(lower)
          ? CapturedEventKind.travel
          : RegExp(r'вес|вешу|weight').hasMatch(lower)
          ? CapturedEventKind.weight
          : CapturedEventKind.complaint;
      String? date;
      String? issue;
      final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(source);
      final numeric = RegExp(
        r'\b(\d{1,2})[./](\d{1,2})(?:[./](\d{4}|\d{2}))?\b',
      ).firstMatch(source);
      const months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря',
      ];
      final named = RegExp(
        r'(\d{1,2})\s+(' + months.join('|') + r')(?:\s+(\d{4}))?',
        caseSensitive: false,
      ).firstMatch(source);
      final relative = RegExp(
        r'(?:^|[\s,(])(позавчера|вчера|сегодня|today|yesterday)(?=$|[\s,).])',
        caseSensitive: false,
        unicode: true,
      ).firstMatch(source);
      try {
        if (iso != null) {
          date = CalendarDate.parse(iso[0]!).toString();
        } else if (numeric != null && numeric[3] != null) {
          var year = int.parse(numeric[3]!);
          if (year < 100) year += 2000;
          date = CalendarDate(
            year,
            int.parse(numeric[2]!),
            int.parse(numeric[1]!),
          ).toString();
        } else if (named != null && named[3] != null) {
          date = CalendarDate(
            int.parse(named[3]!),
            months.indexOf(named[2]!.toLowerCase()) + 1,
            int.parse(named[1]!),
          ).toString();
        } else if (relative != null) {
          final word = relative[1]!.toLowerCase(),
              days = word == 'сегодня' || word == 'today'
                  ? 0
                  : word == 'позавчера'
                  ? 2
                  : 1;
          final value = DateTime.utc(
            today.year,
            today.month,
            today.day,
          ).subtract(Duration(days: days));
          date = CalendarDate(value.year, value.month, value.day).toString();
        } else if (numeric != null || named != null) {
          issue = 'missing_year';
        }
      } on FormatException {
        issue = 'invalid_date';
      } on ArgumentError {
        issue = 'invalid_date';
      }
      final weight = kind == CapturedEventKind.weight
          ? RegExp(
              r'(\d+(?:[.,]\d+)?)\s*(кг|kg)(?=$|[\s,).])',
              caseSensitive: false,
            ).firstMatch(source)
          : null;
      final temperature = kind == CapturedEventKind.illness
          ? RegExp(
              r'(?:температур[аы]|темп\.|temperature|t°)\s*(?:была|до|was|up to)?\s*[:=]?\s*(\d{2}(?:[.,]\d+)?)',
              caseSensitive: false,
            ).firstMatch(source)
          : null;
      var title = source;
      final dateText = iso?[0] ?? numeric?[0] ?? named?[0] ?? relative?[0];
      if (dateText != null && kind != CapturedEventKind.travel) {
        title = title.replaceFirst(dateText, ' ');
      }
      if (temperature != null) title = title.replaceFirst(temperature[0]!, '');
      title = title
          .replaceFirst(
            RegExp(
              r'^\s*(?:с\s+)?(?:я\s+)?(?:болел[аи]?|заболел[аи]?|принимал[аи]?|переболел[аи]?|прописали|назначили|was ill with|taking)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
      if (kind == CapturedEventKind.weight) {
        title = RegExp('[а-яё]', caseSensitive: false).hasMatch(source)
            ? 'Вес'
            : 'Weight';
      }
      rows.add(
        EventCaptureRow(
          id: newId(),
          kind: kind,
          source: source,
          start: at + chunk.indexOf(source),
          end: at + chunk.indexOf(source) + source.length,
          issue: issue,
          fields: {
            'name': title.isEmpty ? source : title,
            'from': date ?? '',
            'to': '',
            'temperature': temperature?[1] ?? '',
            'value': weight?[1] ?? '',
            'unit': weight == null ? '' : 'kg',
          },
        ),
      );
    }
    return List.unmodifiable(rows);
  }
}

/// Called only by the explicit confirmation command, after manual review.
List<HealthRecord> confirmedEventRecords(
  List<EventCaptureRow> rows,
  MedicalProfile profile,
) {
  if (rows.isEmpty) throw const InvalidRecord('events');
  var context = profile.details ?? ProfileDetails();
  final events = context.events.toList(), records = <HealthRecord>[];
  var profileChanged = false;
  for (final row in rows) {
    String field(String key) => row.fields[key]?.trim() ?? '';
    CalendarDate? optional(String key) =>
        field(key).isEmpty ? null : CalendarDate.parse(field(key));
    final name = field('name');
    if (name.isEmpty) throw const InvalidRecord('name');
    final evidence = row.source;
    if (row.kind == CapturedEventKind.travel) {
      final fields = Map<ProfileField, String>.of(context.fields);
      fields[ProfileField.travel] = [
        context[ProfileField.travel],
        name,
      ].where((v) => v.isNotEmpty).join('; ');
      context = context.copyWith(fields: fields);
      profileChanged = true;
      continue;
    }
    final start = row.kind == CapturedEventKind.allergy
        ? null
        : optional('from');
    final end =
        [
          CapturedEventKind.illness,
          CapturedEventKind.hospitalization,
          CapturedEventKind.medication,
        ].contains(row.kind)
        ? optional('to')
        : null;
    if (row.kind != CapturedEventKind.allergy && start == null) {
      throw const InvalidRecord('date');
    }
    if (row.kind == CapturedEventKind.medication) {
      records.add(
        MedicationCourse(
          id: row.id,
          profileId: profile.id,
          name: name,
          start: start!,
          end: field('mode') == 'constant' ? null : end,
          regimen: field('mode') == 'constant'
              ? MedicationRegimen.ongoing
              : MedicationRegimen.course,
          schedule: field('schedule'),
          prescribedBy: field('prescriber'),
          reason: field('reason'),
          experience: field('experience').isEmpty
              ? null
              : MedicationExperience.values.byName(field('experience')),
          notes: evidence,
        ),
      );
    } else if (row.kind == CapturedEventKind.weight) {
      if (field('unit').isEmpty) throw const InvalidRecord('unit');
      records.add(
        HomeMeasurement(
          id: row.id,
          profileId: profile.id,
          name: name,
          date: start!,
          value: SourceValue(field('value'), ResultValueKind.numeric),
          unit: field('unit'),
          notes: evidence,
        ),
      );
    } else {
      final kind = switch (row.kind) {
        CapturedEventKind.illness => ProfileEventKind.illness,
        CapturedEventKind.hospitalization => ProfileEventKind.hospitalization,
        CapturedEventKind.allergy => ProfileEventKind.allergy,
        _ => ProfileEventKind.complaint,
      };
      events.add(
        ProfileEvent(
          id: row.id,
          kind: kind,
          name: name,
          start: start,
          end: end,
          fields: {
            ProfileEventField.sourceText: evidence,
            if (kind == ProfileEventKind.illness &&
                field('temperature').isNotEmpty)
              ProfileEventField.temperature: field('temperature'),
            if (kind == ProfileEventKind.hospitalization &&
                field('institution').isNotEmpty)
              ProfileEventField.institution: field('institution'),
            if (kind == ProfileEventKind.hospitalization &&
                field('outcomes').isNotEmpty)
              ProfileEventField.outcomes: field('outcomes'),
            if (kind == ProfileEventKind.allergy &&
                field('reaction').isNotEmpty)
              ProfileEventField.reaction: field('reaction'),
          },
        ),
      );
      profileChanged = true;
    }
  }
  if (profileChanged) {
    records.insert(
      0,
      profile.copyWith(details: context.copyWith(events: events)),
    );
  }
  for (final record in records) {
    record.validate();
  }
  return List.unmodifiable(records);
}
