import 'package:document_processing/document_processing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import 'event_capture_view.dart';
import 'event_capture_view_model.dart';

/// Inline single-record entry with the same review and retry command boundary.
class EventRecordForm extends StatefulWidget {
  const EventRecordForm({
    required this.profile,
    required this.today,
    required this.kind,
    required this.newId,
    required this.save,
    super.key,
  });
  final MedicalProfile profile;
  final CalendarDate today;
  final CapturedEventKind kind;
  final String Function() newId;
  final Future<bool> Function(List<HealthRecord>, String) save;
  @override
  State<EventRecordForm> createState() => _EventRecordFormState();
}

class _EventRecordFormState extends State<EventRecordForm> {
  late final model = EventCaptureViewModel(
    profile: widget.profile,
    today: widget.today,
    newId: widget.newId,
    save: widget.save,
    initialRows: [_row()],
  );
  EventCaptureRow _row() => EventCaptureRow(
    id: widget.newId(),
    kind: widget.kind,
    source: '',
    start: 0,
    end: 0,
    fields: widget.kind == CapturedEventKind.weight
        ? {'name': 'Weight', 'unit': 'kg'}
        : {},
  );
  void saved() {
    model.rows = [_row()];
    model.update(model.rows!.single);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      EventCaptureView(model: model, singleRecord: true, onSaved: saved);
}
