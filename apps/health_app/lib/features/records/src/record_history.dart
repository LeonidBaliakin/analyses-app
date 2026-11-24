import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'records_view_model.dart';

String recordName(HealthRecord r) => switch (r) {
  MedicalProfile() => r.name,
  LabResult() => r.name,
  MedicationCourse() => r.name,
  HomeMeasurement() => r.name,
};

List<(String, String)> recordFields(AppLocalizations l, HealthRecord r) => [
  (l.nameLabel, recordName(r)),
  ...switch (r) {
    MedicalProfile() => [
      (l.birthDate, r.birthDate?.toString() ?? ''),
      (l.profileHistory, r.history),
      (l.profileAllergies, r.allergies),
      (l.localNotes, r.notes),
    ],
    LabResult() => [
      (l.dateLabel, r.date.toString()),
      (l.localValue, r.value.raw),
      (l.localUnit, r.unit),
      (l.localReference, r.reference),
      (l.labLabel, r.laboratory),
      (l.localMethod, r.method),
      (l.localSpecimen, r.specimen),
      (l.localNotes, r.notes),
    ],
    MedicationCourse() => [
      (l.localStartDate, r.start.toString()),
      (l.localEndDate, r.end?.toString() ?? ''),
      (l.localDosage, r.dosage),
      (l.localSchedule, r.schedule),
      (l.localPrescribedBy, r.prescribedBy),
      (l.localNotes, r.notes),
    ],
    HomeMeasurement() => [
      (l.dateLabel, r.date.toString()),
      (l.localValue, r.value.raw),
      (l.localUnit, r.unit),
      if (r.minuteOfDay != null)
        (
          l.localTime,
          '${(r.minuteOfDay! ~/ 60).toString().padLeft(2, '0')}:${(r.minuteOfDay! % 60).toString().padLeft(2, '0')}',
        ),
      if (r.utcOffsetMinutes != null)
        (
          l.localOffset,
          '${r.utcOffsetMinutes! < 0 ? '-' : '+'}${(r.utcOffsetMinutes!.abs() ~/ 60).toString().padLeft(2, '0')}:${(r.utcOffsetMinutes!.abs() % 60).toString().padLeft(2, '0')}',
        ),
      (l.localSource, r.source),
      (l.localNotes, r.notes),
    ],
  },
];

Future<void> showRecordHistory(
  BuildContext context,
  RecordsViewModel model,
  String id,
) {
  var future = model.history(id);
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.localHistory),
        content: SizedBox(
          width: 600,
          child: FutureBuilder<List<RecordEntry>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.localHistoryError),
                    TextButton(
                      onPressed: () => setState(() {
                        future = model.history(id);
                      }),
                      child: Text(l.retry),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in snapshot.data!) ...[
                      Text(
                        '${l.localRevision} ${entry.revision}${entry.deleted ? ' · ${l.localDeleted}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      for (final (label, value) in recordFields(
                        l,
                        entry.record,
                      ))
                        if (value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$label: $value'),
                          ),
                      const Divider(height: 24),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.localClose),
          ),
        ],
      ),
    ),
  );
}
