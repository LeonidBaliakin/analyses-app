import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/record_fields.dart';
import '../../../presentation/reference_widgets.dart';
import 'record_editor.dart';
import '../../profile/profile.dart';
import '../../capture/capture.dart';

import 'package:document_processing/document_processing.dart';

import 'records_view_model.dart';

Future<void> showRecordActivity(
  BuildContext context,
  RecordsViewModel model, {
  bool diary = false,
}) {
  final l = AppLocalizations.of(context);
  if (model.profile == null) {
    return showRecordEditor(context, model, RecordKind.profile);
  }
  return showReferenceSheet(
    context,
    diary ? l.measurementDiary : l.addEvent,
    ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final entries = model.entries
            .where(
              (entry) =>
                  !entry.deleted &&
                  (diary
                      ? entry.record is HomeMeasurement
                      : entry.record is HomeMeasurement ||
                            entry.record is MedicationCourse),
            )
            .toList();
        entries.sort((a, b) {
          CalendarDate date(HealthRecord record) => record is HomeMeasurement
              ? record.date
              : (record as MedicationCourse).start;
          return date(b.record).compareTo(date(a.record));
        });
        if (!diary) {
          return ProfileCoursesView(
            addForm: EventRecordForm(
              profile: model.profile!.record as MedicalProfile,
              today: model.today,
              kind: CapturedEventKind.medication,
              newId: model.newId,
              save: (records, operation) => model.saveBatch([
                for (final record in records)
                  RecordMutation(
                    operationId: '$operation:${record.id}',
                    record: record,
                    expectedRevision: 0,
                  ),
              ]),
            ),
            courses: entries
                .where((e) => e.record is MedicationCourse)
                .map((e) => e.record as MedicationCourse)
                .toList(),
            today: model.today,
            onAdd: () =>
                showRecordEditor(context, model, RecordKind.medication),
            onEdit: (r) => showRecordEditor(
              context,
              model,
              RecordKind.medication,
              entry: entries.firstWhere((e) => e.record.id == r.id),
            ),
            onExperience: (r, value) {
              final old = entries.firstWhere((e) => e.record.id == r.id);
              model.save(
                RecordMutation(
                  operationId: model.newId(),
                  expectedRevision: old.revision,
                  record: MedicationCourse(
                    id: r.id,
                    profileId: r.profileId,
                    name: r.name,
                    start: r.start,
                    end: r.end,
                    dosage: r.dosage,
                    schedule: r.schedule,
                    prescribedBy: r.prescribedBy,
                    reason: r.reason,
                    experience: value,
                    regimen: r.regimen,
                    notes: r.notes,
                  ),
                ),
              );
            },
            onRemove: (r) {
              final old = entries.firstWhere((e) => e.record.id == r.id);
              model.save(
                RecordMutation(
                  operationId: model.newId(),
                  record: r,
                  expectedRevision: old.revision,
                  delete: true,
                ),
              );
            },
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      showRecordEditor(context, model, RecordKind.measurement),
                  icon: const Icon(Icons.add),
                  label: Text(l.localAddMeasurement),
                ),
                if (!diary)
                  OutlinedButton.icon(
                    onPressed: () =>
                        showRecordEditor(context, model, RecordKind.medication),
                    icon: const Icon(Icons.medication_outlined),
                    label: Text(l.localAddMedication),
                  ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.historyNoEvents),
              ),
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  recordFields(l, entry.record)
                      .where((f) => f.$2.isNotEmpty)
                      .map((f) => '${f.$1}: ${f.$2}')
                      .join('\n'),
                ),
                trailing: IconButton(
                  tooltip: l.localEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showRecordEditor(
                    context,
                    model,
                    entry.record.kind,
                    entry: entry,
                  ),
                ),
              ),
          ],
        );
      },
    ),
    fullscreen: false,
  );
}
