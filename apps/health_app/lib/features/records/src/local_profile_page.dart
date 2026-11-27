import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/demo_catalog.dart';
import '../../profile/profile.dart';
import 'record_activity.dart';
import 'local_capture.dart';
import 'record_editor.dart';
import 'record_history.dart';
import 'records_page.dart';
import 'records_view_model.dart';

/// Composition adapter: profile views receive domain snapshots and save
/// callbacks; they do not import the storage-owning records implementation.
class LocalProfilePage extends StatelessWidget {
  const LocalProfilePage({
    required this.model,
    required this.catalog,
    this.onDocuments,
    super.key,
  });
  final RecordsViewModel model;
  final DemoCatalog catalog;
  final VoidCallback? onDocuments;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final entry = model.profile;
      if (entry == null) {
        return RecordsPage(
          model: model,
          section: RecordsSection.profile,
          onOpenOriginals: onDocuments,
        );
      }
      var revision = entry.revision;
      final l = AppLocalizations.of(context);
      return ProfilePage(
        catalog: catalog,
        localProfile: entry.record as MedicalProfile,
        medications: model
            .ofKind(RecordKind.medication)
            .map((e) => e.record as MedicationCourse)
            .toList(),
        measurements: model
            .ofKind(RecordKind.measurement)
            .map((e) => e.record as HomeMeasurement)
            .toList(),
        newId: model.newId,
        onSaveProfile: (profile, operation) async {
          final saved = await model.save(
            RecordMutation(
              operationId: operation,
              record: profile,
              expectedRevision: revision,
            ),
          );
          if (saved) revision++;
          return saved;
        },
        onDiary: () => showLocalEventCapture(context, model, diary: true),
        onAddEvent: () => showLocalEventCapture(context, model),
        onMedication: () => showRecordActivity(context, model),
        onWeight: () => showRecordActivity(context, model, diary: true),
        onDocuments: onDocuments,
        extraChildren: [
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => showRecordEditor(
                  context,
                  model,
                  RecordKind.profile,
                  entry: entry,
                ),
                child: Text(l.localEditProfile),
              ),
              TextButton(
                onPressed: () =>
                    showRecordHistory(context, model, entry.record.id),
                child: Text(l.localHistory),
              ),
            ],
          ),
          for (final text in [
            (entry.record as MedicalProfile).history,
            (entry.record as MedicalProfile).allergies,
            (entry.record as MedicalProfile).notes,
          ])
            if (text.isNotEmpty) Text(text),
        ],
      );
    },
  );
}

Future<void> showLocalProfileSection(
  BuildContext context,
  RecordsViewModel model,
  ProfileSection section,
) async {
  final entry = model.profile;
  if (entry == null) {
    await showRecordEditor(context, model, RecordKind.profile);
    return;
  }
  var revision = entry.revision;
  await showProfileSectionEditor(
    context,
    title: AppLocalizations.of(context).profileBase,
    section: section,
    profile: entry.record as MedicalProfile,
    newId: model.newId,
    save: (profile, operation) async {
      final saved = await model.save(
        RecordMutation(
          operationId: operation,
          record: profile,
          expectedRevision: revision,
        ),
      );
      if (saved) revision++;
      return saved;
    },
  );
}
