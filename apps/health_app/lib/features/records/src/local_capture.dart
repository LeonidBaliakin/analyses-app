import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../capture/capture.dart';
import 'record_editor.dart';
import 'records_view_model.dart';

/// Composition boundary owns optimistic revisions and transactional persistence.
Future<void> showLocalEventCapture(
  BuildContext context,
  RecordsViewModel model, {
  bool diary = false,
}) async {
  final entry = model.profile;
  if (entry == null) {
    await showRecordEditor(context, model, RecordKind.profile);
    return;
  }
  Future<bool> save(List<HealthRecord> records, String operation) =>
      model.saveBatch([
        for (final r in records)
          RecordMutation(
            operationId: '$operation:${r.id}',
            record: r,
            expectedRevision: r is MedicalProfile ? entry.revision : 0,
          ),
      ]);
  if (diary) {
    await showMeasurementDiary(
      context,
      profileId: entry.record.id,
      today: model.today,
      newId: model.newId,
      save: save,
      entries: model
          .ofKind(RecordKind.measurement)
          .map((e) => e.record as HomeMeasurement)
          .toList(),
    );
  } else {
    await showEventCapture(
      context,
      profile: entry.record as MedicalProfile,
      today: model.today,
      newId: model.newId,
      save: save,
    );
  }
}
