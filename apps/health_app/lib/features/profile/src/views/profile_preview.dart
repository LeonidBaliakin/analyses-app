import 'package:medical_domain/medical_domain.dart';
import 'package:document_processing/document_processing.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../capture/capture.dart';
import 'profile_courses.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../view_models/demo_profile.dart';
import '../view_models/profile_editor_view_model.dart';
import 'profile_editor.dart';

Future<void> showDemoProfileSection(
  BuildContext context,
  DemoCatalog catalog,
  ProfileSection section, {
  Future<void> Function()? onSaveAttempt,
}) {
  var sequence = 0;
  return showProfileSectionEditor(
    context,
    title: profileTitle(context, section.index),
    section: section,
    profile: demoProfile(catalog),
    newId: () => 'preview-${sequence++}',
    save: (_, _) async {
      await onSaveAttempt?.call();
      return false;
    },
  );
}

Future<void> showDemoEventCapture(
  BuildContext context,
  DemoCatalog catalog, {
  bool diary = false,
  Future<void> Function()? onSaveAttempt,
}) {
  var sequence = 0;
  final now = DateTime.now(),
      today = CalendarDate(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
  Future<bool> save(List<HealthRecord> records, String operation) async {
    await (onSaveAttempt?.call() ??
        showUnavailable(context, AppLocalizations.of(context).signIn));
    return false;
  }

  if (diary) {
    return showMeasurementDiary(
      context,
      profileId: 'synthetic-preview',
      today: today,
      newId: () => 'preview-${now.microsecondsSinceEpoch}-${sequence++}',
      save: save,
    );
  }
  return showEventCapture(
    context,
    profile: demoProfile(catalog),
    today: today,
    newId: () => 'preview-${now.microsecondsSinceEpoch}-${sequence++}',
    save: save,
  );
}

Future<void> showDemoCourses(
  BuildContext context,
  DemoCatalog catalog, {
  Future<void> Function()? onSaveAttempt,
  bool weight = false,
}) {
  final l = AppLocalizations.of(context), now = DateTime.now();
  var sequence = 0;
  Future<void> gate() async {
    await (onSaveAttempt?.call() ?? showUnavailable(context, l.signIn));
  }

  void add() {
    showEventCapture(
      context,
      profile: demoProfile(catalog),
      today: CalendarDate(now.year, now.month, now.day),
      newId: () => 'preview-${sequence++}',
      save: (_, _) async {
        await gate();
        return false;
      },
      initialRows: [
        EventCaptureRow(
          id: 'preview-new',
          kind: weight
              ? CapturedEventKind.weight
              : CapturedEventKind.medication,
          source: '',
          start: 0,
          end: 0,
          fields: weight ? {'unit': 'kg'} : {},
        ),
      ],
    );
  }

  if (weight) {
    return showReferenceSheet(
      context,
      l.profileWeight,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(onPressed: add, child: Text(l.profileAddRecord)),
          const SizedBox(height: 14),
          for (final row in catalog.events['weight'] as List)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${row['d']} · ${row['kg']} kg'),
              trailing: IconButton(
                onPressed: gate,
                icon: const Icon(Icons.close, size: 16),
                tooltip: l.profileRemoveEntry,
              ),
            ),
        ],
      ),
    );
  }
  final courses = [
    for (final row in catalog.events['med'] as List)
      MedicationCourse(
        id: 'preview-${sequence++}',
        profileId: 'synthetic-preview',
        name: row['n'] as String,
        start: CalendarDate.parse(row['f'] as String),
        end: (row['t'] as String? ?? '').isEmpty
            ? null
            : CalendarDate.parse(row['t'] as String),
        prescribedBy: row['who'] as String? ?? '',
        reason: row['why'] as String? ?? '',
        regimen: row['m'] == 'Постоянно'
            ? MedicationRegimen.ongoing
            : MedicationRegimen.course,
      ),
  ];
  return showReferenceSheet(
    context,
    l.profileMedicines,
    ProfileCoursesView(
      addForm: EventRecordForm(
        profile: demoProfile(catalog),
        today: CalendarDate(now.year, now.month, now.day),
        kind: CapturedEventKind.medication,
        newId: () => 'preview-${sequence++}',
        save: (_, _) async {
          await gate();
          return false;
        },
      ),
      courses: courses,
      today: CalendarDate(now.year, now.month, now.day),
      onAdd: add,
      onEdit: (_) => gate(),
      onRemove: (_) => gate(),
      onExperience: (_, _) => gate(),
    ),
  );
}
