import 'package:medical_domain/medical_domain.dart';

/// Display projection. It never classifies medical results or infers diagnoses.
final class ProfileOverviewState {
  ProfileOverviewState(
    MedicalProfile profile,
    Iterable<MedicationCourse> medications,
    Iterable<HomeMeasurement> measurements,
  ) : details = profile.details ?? ProfileDetails(),
      medications = List.unmodifiable(medications),
      measurements = List.unmodifiable(measurements),
      birthDate = profile.birthDate;
  final ProfileDetails details;
  final CalendarDate? birthDate;
  final List<MedicationCourse> medications;
  final List<HomeMeasurement> measurements;
  int count(int section) => switch (section) {
    0 =>
      details.events.where((e) => e.kind == ProfileEventKind.complaint).length,
    1 => [
      birthDate?.toString() ?? '',
      details[ProfileField.sex],
      details[ProfileField.height],
    ].where((s) => s.isNotEmpty).length,
    2 => medications.length,
    3 =>
      measurements
          .where(
            (e) =>
                e.name.toLowerCase() == 'weight' ||
                e.name.toLowerCase() == 'вес',
          )
          .length,
    4 => details.events.where((e) => e.kind == ProfileEventKind.illness).length,
    5 =>
      details.events
          .where((e) => e.kind == ProfileEventKind.hospitalization)
          .length,
    6 => details.events.where((e) => e.kind == ProfileEventKind.allergy).length,
    7 => details.history.length,
    8 => [
      ProfileField.activity,
      ProfileField.stress,
      ProfileField.sleep,
      ProfileField.diet,
      ProfileField.smoking,
      ProfileField.alcohol,
    ].where((f) => details[f].isNotEmpty).length,
    _ => 0,
  };
  int get completeness =>
      ((List.generate(9, count).where((n) => n > 0).length / 9) * 100).round();
}
