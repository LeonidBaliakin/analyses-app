import 'package:design_system/design_system.dart';
import 'package:document_processing/document_processing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/reference_widgets.dart';
import '../../../presentation/calendar_input.dart';
import 'event_capture_view_model.dart';

Future<void> showEventCapture(
  BuildContext context, {
  required MedicalProfile profile,
  required CalendarDate today,
  required String Function() newId,
  required Future<bool> Function(List<HealthRecord>, String) save,
  List<EventCaptureRow>? initialRows,
  String? title,
}) async {
  final model = EventCaptureViewModel(
    profile: profile,
    today: today,
    newId: newId,
    save: save,
    initialRows: initialRows,
  );
  try {
    await showReferenceSheet(
      context,
      title ?? AppLocalizations.of(context).addEvent,
      EventCaptureView(model: model),
      titleWidget: ListenableBuilder(
        listenable: model,
        builder: (context, _) => Text(
          model.rows == null
              ? (title ?? AppLocalizations.of(context).addEvent)
              : AppLocalizations.of(context).captureReview,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),

      maxWidth: 640,
    );
  } finally {
    model.dispose();
  }
}

class EventCaptureView extends StatefulWidget {
  const EventCaptureView({
    required this.model,
    this.singleRecord = false,
    this.onSaved,
    super.key,
  });
  final bool singleRecord;
  final VoidCallback? onSaved;
  final EventCaptureViewModel model;
  @override
  State<EventCaptureView> createState() => _EventCaptureViewState();
}

class _EventCaptureViewState extends State<EventCaptureView> {
  final _dates = <String, TextEditingController>{};
  @override
  void dispose() {
    for (final c in _dates.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool example = false, voice = false;
  CapturedEventKind extra = CapturedEventKind.illness;
  String _kind(AppLocalizations l, CapturedEventKind k) => switch (k) {
    CapturedEventKind.illness => l.captureIllness,
    CapturedEventKind.medication => l.captureMedication,
    CapturedEventKind.hospitalization => l.captureHospital,
    CapturedEventKind.complaint => l.captureComplaint,
    CapturedEventKind.weight => l.captureWeight,
    CapturedEventKind.allergy => l.captureAllergy,
    CapturedEventKind.travel => l.captureTravel,
  };
  Widget _select(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: Text(o.$2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: widget.model.saving ? null : (v) => change(v!),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model,
          l = AppLocalizations.of(context),
          p = OrangePalette.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (m.rows == null) ...[
            Text(
              l.captureWhat,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            TextFormField(
              key: const ValueKey('event-story'),
              initialValue: m.story,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(hintText: l.captureHint),
              onChanged: (v) => m.story = v,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => voice = true),
                  icon: const Icon(Icons.mic_none),
                  label: Text(l.captureDictate),
                ),
                TextButton(
                  onPressed: () => setState(() => example = !example),
                  child: Text(l.captureExample),
                ),
                FilledButton(
                  onPressed: () => m.review(),
                  child: Text(l.captureCheck),
                ),
              ],
            ),
            if (example)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l.captureSample),
              ),
            if (voice)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l.captureVoiceHint),
              ),
          ] else ...[
            if (!widget.singleRecord)
              QuietFold(
                title: Text(l.captureSource),
                children: [SelectableText(m.story)],
              ),
            if (!widget.singleRecord)
              Text(
                l.captureLocalHint,
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            const SizedBox(height: 12),
            for (final row in m.rows!) _row(context, row),
            if (!widget.singleRecord)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: _select(
                      l.captureKind,
                      extra.name,
                      [
                        for (final k in CapturedEventKind.values)
                          (k.name, _kind(l, k)),
                      ],
                      (v) => setState(
                        () => extra = CapturedEventKind.values.byName(v),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: m.saving ? null : () => m.add(extra),
                    child: Text(l.profileAdd),
                  ),
                ],
              ),
            if (m.invalid) Text(l.localInvalid, style: TextStyle(color: p.red)),
            if (m.failed)
              Text(l.localSaveError, style: TextStyle(color: p.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: m.saving
                  ? null
                  : () async {
                      if (await m.confirm() && context.mounted) {
                        if (widget.singleRecord) {
                          widget.onSaved?.call();
                        } else {
                          Navigator.of(context).pop();
                        }
                      }
                    },
              child: Text(
                widget.singleRecord ? l.profileAdd : l.captureConfirm,
              ),
            ),
          ],
        ],
      );
    },
  );
  Widget _row(BuildContext context, EventCaptureRow row) {
    final m = widget.model, l = AppLocalizations.of(context);
    void put(String k, String value) =>
        m.update(row.edit(fields: {...row.fields, k: value}));
    Widget field(String key, String label, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: OrangePalette.of(context).secondary,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: ValueKey('${row.id}:$key'),
            controller: key == 'from' || key == 'to'
                ? _dates.putIfAbsent(
                    '${row.id}:$key',
                    () => TextEditingController(text: row.fields[key] ?? ''),
                  )
                : null,
            initialValue: key == 'from' || key == 'to'
                ? null
                : row.fields[key] ?? '',
            enabled: !m.saving,
            maxLines: lines,
            decoration: InputDecoration(
              filled: true,
              fillColor: OrangePalette.of(context).paper,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              hintText: key == 'from' || key == 'to' ? l.localDateHint : null,
              suffixIcon: key == 'from' || key == 'to'
                  ? IconButton(
                      tooltip: l.chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 17),
                      onPressed: m.saving
                          ? null
                          : () async {
                              final value = await pickCalendarDate(
                                context,
                                row.fields[key] ?? '',
                              );
                              if (value != null) {
                                _dates['${row.id}:$key']!.text = value;
                                put(key, value);
                              }
                            },
                    )
                  : null,
            ),
            onChanged: (v) => put(key, v),
          ),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.singleRecord)
          _select(
            l.captureKind,
            row.kind.name,
            [for (final k in CapturedEventKind.values) (k.name, _kind(l, k))],
            (v) => m.update(row.edit(kind: CapturedEventKind.values.byName(v))),
          ),
        field(
          'name',
          row.kind == CapturedEventKind.travel
              ? l.profileFieldTravel
              : switch (row.kind) {
                  CapturedEventKind.medication => l.captureMedicationName,
                  CapturedEventKind.illness => l.captureIllnessName,
                  CapturedEventKind.complaint => l.captureComplaintName,
                  CapturedEventKind.hospitalization => l.captureHospitalName,
                  CapturedEventKind.allergy => l.captureAllergyName,
                  _ => l.profileEventName,
                },
          lines: 2,
        ),
        if (row.kind != CapturedEventKind.travel) ...[
          if (row.kind != CapturedEventKind.allergy) ...[
            field(
              'from',
              row.kind == CapturedEventKind.weight
                  ? l.dateLabel
                  : l.captureStartDate,
            ),
            if (row.issue != null && (row.fields['from'] ?? '').isEmpty)
              Text(l.captureMissingDate),
          ],
          if (row.kind != CapturedEventKind.weight &&
              row.kind != CapturedEventKind.allergy &&
              row.kind != CapturedEventKind.complaint &&
              (row.fields['mode'] ?? '') != 'constant')
            field('to', l.captureEndDate),
          if (row.kind == CapturedEventKind.illness)
            field('temperature', l.profileTemperature),
          if (row.kind == CapturedEventKind.hospitalization) ...[
            field('institution', l.profileInstitution),
            field('outcomes', l.profileOutcomes, lines: 3),
          ],
          if (row.kind == CapturedEventKind.allergy)
            field('reaction', l.profileReaction),
          if (row.kind == CapturedEventKind.weight) ...[
            field('value', l.localValue),
            field('unit', l.localUnit),
          ],
          if (row.kind == CapturedEventKind.medication) ...[
            _select(l.medicationMode, row.fields['mode'] ?? 'course', [
              ('course', l.medicationCourse),
              ('constant', l.medicationConstant),
            ], (v) => put('mode', v)),
            _select(l.medicationExperience, row.fields['experience'] ?? '', [
              ('', l.profileNotStated),
              ('firstCourse', l.medicationFirstCourse),
              ('repeatCourse', l.medicationRepeatCourse),
              ('unknown', l.medicationUnknownCourse),
            ], (v) => put('experience', v)),
            field('schedule', l.localSchedule),
            field('prescriber', l.localPrescribedBy),
            field('reason', l.medicationReason),
          ],
        ],
        if (!widget.singleRecord)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: m.saving ? null : () => m.remove(row.id),
              child: Text(l.profileRemoveEntry),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: widget.singleRecord ? content : PaperCard(child: content),
    );
  }
}
