import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

import '../l10n/generated/app_localizations.dart';

String recordName(HealthRecord r) => switch (r) {
  MedicalProfile() => r.name,
  LabResult() => r.name,
  MedicationCourse() => r.name,
  HomeMeasurement() => r.name,
};

List<(String, String)> recordFields(
  AppLocalizations l,
  HealthRecord r, {
  TerminologyCatalog? terminology,
}) => [
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
      if (r.coding case final c?) ...[
        (
          l.terminologyIndicator,
          (terminology ?? bundledTerminology).releases[c.terminologyReleaseId]
                  ?.indicator(c.indicatorId)
                  ?.label
                  .inLanguage(l.localeName) ??
              c.indicatorId,
        ),
        if (c.unitId != null)
          (
            l.terminologyUnit,
            (terminology ?? bundledTerminology).releases[c.terminologyReleaseId]
                    ?.unit(c.unitId!)
                    ?.symbol ??
                c.unitId!,
          ),
      ],
      (l.localNotes, r.notes),
    ],
    MedicationCourse() => [
      (
        l.medicationMode,
        switch (r.regimen) {
          MedicationRegimen.course => l.medicationCourse,
          MedicationRegimen.ongoing => l.medicationConstant,
          null => l.profileNotStated,
        },
      ),
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
