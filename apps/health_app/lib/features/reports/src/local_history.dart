import 'package:medical_domain/medical_domain.dart';

import 'package:material_ui/material_ui.dart';

import '../../../presentation/category_presentation.dart';
import '../../../presentation/record_fields.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../history/history.dart';

HistoryData localHistoryData(HealthReport report, BuildContext context) =>
    HistoryData(
      rows: [
        for (final series in report.series)
          HistoryRow(
            id: series.results
                .map((r) => r.id)
                .reduce((a, b) => a.compareTo(b) < 0 ? a : b),
            name: series.latest.name,
            group: categoryPresentation(context, series.latest.category).title,
            context: [
              series.latest.laboratory,
              series.latest.specimen,
              series.latest.method,
            ].where((v) => v.isNotEmpty).join(' · '),
            points: [
              for (final result in series.results)
                HistoryPoint(
                  date: result.date,
                  value: result.value.raw,
                  unit: result.unit,
                  reference: result.reference,
                  source: result.laboratory,
                  details: [
                    result.notes,
                    result.documentSource?.fields['evidence'] ?? '',
                  ].where((v) => v.isNotEmpty).join(' · '),
                ),
            ],
          ),
      ],
      events: [
        for (final event in report.profile?.details?.events ?? <ProfileEvent>[])
          if (event.start != null && event.kind != ProfileEventKind.allergy)
            HistoryEvent(
              id: event.id,
              name: event.name,
              start: event.start!,
              end: event.end,
              kind: event.kind == ProfileEventKind.complaint
                  ? HistoryEventKind.complaint
                  : HistoryEventKind.illness,
              detail: event.fields.values
                  .where((v) => v.isNotEmpty)
                  .join(' · '),
            ),
        for (final course in report.medications)
          HistoryEvent(
            id: course.id,
            name: course.name,
            start: course.start,
            end: course.end,
            kind: HistoryEventKind.medication,
            detail: [
              course.dosage,
              course.schedule,
              course.prescribedBy,
              course.reason,
              course.notes,
            ].where((v) => v.isNotEmpty).join(' · '),
          ),
        for (final measurement in report.measurements)
          HistoryEvent(
            id: measurement.id,
            name: measurement.name,
            start: measurement.date,
            kind: HistoryEventKind.measurement,
            detail: recordFields(AppLocalizations.of(context), measurement)
                .where((f) => f.$2.isNotEmpty)
                .map((f) => '${f.$1}: ${f.$2}')
                .join(' · '),
          ),
      ],
    );
