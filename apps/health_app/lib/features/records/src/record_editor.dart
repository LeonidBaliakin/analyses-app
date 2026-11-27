import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/category_presentation.dart';
import '../../../presentation/calendar_input.dart';
import 'record_history.dart';
import 'records_view_model.dart';
import 'result_coding_view_model.dart';
import 'result_coding_fields.dart';

Future<void> showRecordEditor(
  BuildContext context,
  RecordsViewModel model,
  RecordKind kind, {
  RecordEntry? entry,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RecordEditor(model: model, kind: kind, entry: entry),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).localSaved)),
    );
  }
}

class _RecordEditor extends StatefulWidget {
  const _RecordEditor({required this.model, required this.kind, this.entry});
  final RecordsViewModel model;
  final RecordKind kind;
  final RecordEntry? entry;
  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<_RecordEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late final String _id =
      widget.entry?.record.id ??
      (widget.kind == RecordKind.profile
          ? RecordsViewModel.profileId
          : widget.model.newId());
  late String _operation = widget.model.newId();
  late final String _deleteOperation = widget.model.newId();
  AnalysisCategory _category = AnalysisCategory.blood;
  ResultValueKind _valueKind = ResultValueKind.numeric;
  MedicationExperience? _experience;
  MedicationRegimen? _regimen;
  bool _dirty = false;
  String? _invalidField;
  late final ResultCodingViewModel _coding;

  @override
  void initState() {
    super.initState();
    final r = widget.entry?.record;
    final values = <String, String>{
      'date': widget.model.today.toString(),
      'start': widget.model.today.toString(),
    };
    if (r != null) {
      values['name'] = recordName(r);
      switch (r) {
        case MedicalProfile():
          values.addAll({
            'birthDate': r.birthDate?.toString() ?? '',
            'history': r.history,
            'allergies': r.allergies,
            'notes': r.notes,
          });
        case LabResult():
          _category = r.category;
          _valueKind = r.value.kind;
          values.addAll({
            'date': r.date.toString(),
            'value': r.value.raw,
            'unit': r.unit,
            'reference': r.reference,
            'laboratory': r.laboratory,
            'method': r.method,
            'specimen': r.specimen,
            'notes': r.notes,
          });
        case MedicationCourse():
          _experience = r.experience;
          _regimen = r.regimen;
          values.addAll({
            'reason': r.reason,
            'start': r.start.toString(),
            'end': r.end?.toString() ?? '',
            'dosage': r.dosage,
            'schedule': r.schedule,
            'prescribedBy': r.prescribedBy,
            'notes': r.notes,
          });
        case HomeMeasurement():
          _valueKind = r.value.kind;
          values.addAll({
            'date': r.date.toString(),
            'value': r.value.raw,
            'unit': r.unit,
            'source': r.source,
            'notes': r.notes,
            'time': r.minuteOfDay == null ? '' : _time(r.minuteOfDay!),
            'offset': r.utcOffsetMinutes == null
                ? ''
                : _offset(r.utcOffsetMinutes!),
          });
      }
    }
    for (final key in [
      'name',
      'date',
      'birthDate',
      'history',
      'allergies',
      'notes',
      'value',
      'unit',
      'reference',
      'laboratory',
      'method',
      'specimen',
      'start',
      'end',
      'dosage',
      'schedule',
      'prescribedBy',
      'reason',
      'source',
      'time',
      'offset',
    ]) {
      _fields[key] = TextEditingController(text: values[key] ?? '');
    }
    _coding = ResultCodingViewModel(
      widget.model.terminology,
      initial: r is LabResult ? r.coding : null,
    );
    _updateCodingSource();
  }

  static String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  static String _offset(int minutes) =>
      '${minutes < 0 ? '-' : '+'}${_time(minutes.abs())}';
  String _text(String key) => _fields[key]!.text;
  CalendarDate _date(String key) => CalendarDate.parse(_text(key));
  CalendarDate? _optionalDate(String key) =>
      _text(key).isEmpty ? null : _date(key);
  void _changed() {
    _dirty = true;
    _operation = widget.model.newId();
    _invalidField = null;
  }

  void _updateCodingSource() => _coding.updateSource(
    name: _text('name'),
    unit: _text('unit'),
    laboratory: _text('laboratory'),
    specimen: _text('specimen'),
    method: _text('method'),
  );

  @override
  void dispose() {
    _coding.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _input(
    String key,
    String label, {
    bool required = false,
    bool date = false,
    int lines = 1,
    String? hint,
  }) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: Key('record-$key'),
        controller: _fields[key],
        onChanged: (_) {
          _changed();
          if (widget.kind == RecordKind.result &&
              const [
                'name',
                'unit',
                'laboratory',
                'specimen',
                'method',
              ].contains(key)) {
            _updateCodingSource();
          }
        },
        minLines: lines,
        maxLines: lines == 1 ? 1 : 6,
        decoration: InputDecoration(
          labelText: label,
          helperText: hint ?? (required ? null : l.localOptional),
          helperMaxLines: 4,
          errorMaxLines: 4,
          hintText: date ? l.localDateHint : null,
          suffixIcon: date
              ? IconButton(
                  tooltip: l.chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  onPressed: widget.model.saving
                      ? null
                      : () async {
                          final value = await pickCalendarDate(
                            context,
                            _text(key),
                          );
                          if (value != null) {
                            _fields[key]!.text = value;
                            _changed();
                          }
                        },
                )
              : key == 'time'
              ? IconButton(
                  tooltip: l.chooseTime,
                  icon: const Icon(Icons.schedule, size: 17),
                  onPressed: widget.model.saving
                      ? null
                      : () async {
                          final value = await pickLocalTime(
                            context,
                            _text(key),
                          );
                          if (value != null) {
                            _fields[key]!.text = value;
                            _changed();
                          }
                        },
                )
              : null,
        ),
        validator: (text) {
          if (required && (text ?? '').trim().isEmpty) return l.localRequired;
          if (date && text!.isNotEmpty) {
            try {
              CalendarDate.parse(text);
            } catch (_) {
              return l.localDateInvalid;
            }
          }
          if (_invalidField == key) {
            return key == 'end'
                ? l.localEndInvalid
                : key == 'time'
                ? l.localTimeInvalid
                : l.localValueInvalid;
          }
          return null;
        },
      ),
    );
  }

  HealthRecord _record() {
    final common = RecordsViewModel.profileId;
    switch (widget.kind) {
      case RecordKind.profile:
        return MedicalProfile(
          id: _id,
          name: _text('name'),
          birthDate: _optionalDate('birthDate'),
          details: (widget.entry?.record as MedicalProfile?)?.details,
          history: _text('history'),
          allergies: _text('allergies'),
          notes: _text('notes'),
        );
      case RecordKind.result:
        return LabResult(
          id: _id,
          profileId: common,
          name: _text('name'),
          date: _date('date'),
          category: _category,
          value: SourceValue(_text('value'), _valueKind),
          unit: _text('unit'),
          reference: _text('reference'),
          laboratory: _text('laboratory'),
          method: _text('method'),
          specimen: _text('specimen'),
          coding: _coding.coding,
          documentSource: switch (widget.entry?.record) {
            LabResult(documentSource: final source) => source,
            _ => null,
          },
          notes: _text('notes'),
        );
      case RecordKind.medication:
        return MedicationCourse(
          id: _id,
          profileId: common,
          name: _text('name'),
          start: _date('start'),
          end: _regimen == MedicationRegimen.ongoing
              ? null
              : _optionalDate('end'),
          regimen: _regimen,
          dosage: _text('dosage'),
          schedule: _text('schedule'),
          prescribedBy: _text('prescribedBy'),
          reason: _text('reason'),
          experience: _experience,
          notes: _text('notes'),
        );
      case RecordKind.measurement:
        int? minutes, offset;
        if (_text('time').isNotEmpty || _text('offset').isNotEmpty) {
          final time = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(_text('time'));
          final zone = RegExp(r'^([+-])(\d{2}):(\d{2})$')
              .firstMatch(_text('offset'));
          if (time == null ||
              zone == null ||
              int.parse(time[1]!) > 23 ||
              int.parse(time[2]!) > 59 ||
              int.parse(zone[3]!) > 59) {
            throw const InvalidRecord('time');
          }
          minutes = int.parse(time[1]!) * 60 + int.parse(time[2]!);
          offset =
              (int.parse(zone[2]!) * 60 + int.parse(zone[3]!)) *
              (zone[1] == '-' ? -1 : 1);
        }
        return HomeMeasurement(
          id: _id,
          profileId: common,
          name: _text('name'),
          date: _date('date'),
          value: SourceValue(_text('value'), _valueKind),
          unit: _text('unit'),
          source: _text('source'),
          minuteOfDay: minutes,
          utcOffsetMinutes: offset,
          notes: _text('notes'),
        );
    }
  }

  Future<void> _save() async {
    _invalidField = null;
    if (!_form.currentState!.validate()) return;
    try {
      final record = _record();
      record.validate();
      final success = await widget.model.save(
        RecordMutation(
          operationId: _operation,
          record: record,
          expectedRevision: widget.entry?.revision ?? 0,
        ),
      );
      if (success && mounted) Navigator.of(context).pop(true);
    } on InvalidRecord catch (error) {
      setState(() => _invalidField = error.field);
      _form.currentState!.validate();
    }
  }

  Future<void> _close() async {
    if (widget.model.saving) return;
    if (_dirty) {
      final l = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.localDiscard),
          content: Text(l.localDiscardText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.localKeepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.localClose),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.localDelete),
        content: Text(l.localDeleteQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.localCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.localDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final success = await widget.model.save(
      RecordMutation(
        operationId: _deleteOperation,
        record: widget.entry!.record,
        expectedRevision: widget.entry!.revision,
        delete: true,
      ),
    );
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final busy = widget.model.saving;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 680,
                maxHeight: MediaQuery.sizeOf(context).height * .9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      kindTitle(l, widget.kind),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: AbsorbPointer(
                          absorbing: busy,
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _input(
                                  'name',
                                  widget.kind == RecordKind.result
                                      ? l.localOriginalName
                                      : widget.kind == RecordKind.measurement
                                      ? l.localMeasurementName
                                      : l.nameLabel,
                                  required: true,
                                ),
                                if (widget.kind == RecordKind.profile) ...[
                                  _input('birthDate', l.birthDate, date: true),
                                  _input('history', l.profileHistory, lines: 3),
                                  _input(
                                    'allergies',
                                    l.profileAllergies,
                                    lines: 2,
                                  ),
                                ],
                                if (widget.kind == RecordKind.result ||
                                    widget.kind == RecordKind.measurement) ...[
                                  _input(
                                    'date',
                                    l.dateLabel,
                                    required: true,
                                    date: true,
                                  ),
                                  if (widget.kind == RecordKind.result) ...[
                                    AppSelect<AnalysisCategory>(
                                      label: l.localCategory,
                                      value: _category,
                                      options: [
                                        for (final c in AnalysisCategory.values)
                                          AppSelectOption(
                                            value: c,
                                            label: categoryPresentation(
                                              context,
                                              c,
                                            ).title,
                                          ),
                                      ],
                                      onChanged: (c) => setState(() {
                                        _category = c;
                                        _changed();
                                      }),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  AppSelect<ResultValueKind>(
                                    label: l.localValueKind,
                                    value: _valueKind,
                                    options: [
                                      for (final k in ResultValueKind.values)
                                        AppSelectOption(
                                          value: k,
                                          label: valueKindTitle(l, k),
                                        ),
                                    ],
                                    onChanged: (k) => setState(() {
                                      _valueKind = k;
                                      _changed();
                                    }),
                                  ),
                                  const SizedBox(height: 16),
                                  _input(
                                    'value',
                                    l.localValue,
                                    hint: l.localValueHint,
                                  ),
                                  _input('unit', l.localUnit),
                                ],
                                if (widget.kind == RecordKind.result) ...[
                                  _input('reference', l.localReference),
                                  _input('laboratory', l.labLabel),
                                  _input('method', l.localMethod),
                                  _input('specimen', l.localSpecimen),
                                  ResultCodingFields(
                                    model: _coding,
                                    onChanged: _changed,
                                  ),
                                  Text(l.localNoInterpretation),
                                  const SizedBox(height: 16),
                                ],
                                if (widget.kind == RecordKind.medication) ...[
                                  _input(
                                    'start',
                                    l.localStartDate,
                                    required: true,
                                    date: true,
                                  ),
                                  if (_regimen != MedicationRegimen.ongoing)
                                    _input('end', l.localEndDate, date: true),
                                  AppSelect<MedicationRegimen?>(
                                    label: l.medicationMode,
                                    value: _regimen,
                                    options: [
                                      AppSelectOption(
                                        value: null,
                                        label: l.profileNotStated,
                                      ),
                                      AppSelectOption(
                                        value: MedicationRegimen.course,
                                        label: l.medicationCourse,
                                      ),
                                      AppSelectOption(
                                        value: MedicationRegimen.ongoing,
                                        label: l.medicationConstant,
                                      ),
                                    ],
                                    onChanged: (value) => setState(() {
                                      _regimen = value;
                                      _changed();
                                    }),
                                  ),
                                  const SizedBox(height: 16),
                                  _input('dosage', l.localDosage),
                                  _input('schedule', l.localSchedule),
                                  _input('prescribedBy', l.localPrescribedBy),
                                  _input('reason', l.medicationReason),
                                  AppSelect<MedicationExperience?>(
                                    label: l.medicationExperience,
                                    value: _experience,
                                    options: [
                                      AppSelectOption(
                                        value: null,
                                        label: l.profileNotStated,
                                      ),
                                      for (final v
                                          in MedicationExperience.values)
                                        AppSelectOption(
                                          value: v,
                                          label: [
                                            l.medicationFirstCourse,
                                            l.medicationRepeatCourse,
                                            l.medicationUnknownCourse,
                                          ][v.index],
                                        ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _experience = v);
                                      _changed();
                                    },
                                  ),
                                ],
                                if (widget.kind == RecordKind.measurement) ...[
                                  _input(
                                    'time',
                                    l.localTime,
                                    hint: l.localTimeHint,
                                  ),
                                  _input('offset', l.localOffset),
                                  _input('source', l.localSource),
                                ],
                                _input('notes', l.localNotes, lines: 3),
                                if (widget.model.error != null)
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      recordsErrorText(l, widget.model.error!),
                                      style: TextStyle(
                                        color: OrangePalette.of(context).red,
                                      ),
                                    ),
                                  ),
                                if (widget.entry != null)
                                  TextButton(
                                    onPressed: () => showRecordHistory(
                                      context,
                                      widget.model,
                                      _id,
                                    ),
                                    child: Text(l.localHistory),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (busy) const LinearProgressIndicator(),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.entry != null &&
                            widget.kind != RecordKind.profile)
                          TextButton(
                            onPressed: busy ? null : _delete,
                            child: Text(l.localDelete),
                          ),
                        TextButton(
                          onPressed: busy ? null : _close,
                          child: Text(l.localCancel),
                        ),
                        FilledButton(
                          key: const Key('record-save'),
                          onPressed: busy ? null : _save,
                          child: Text(l.localSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String kindTitle(AppLocalizations l, RecordKind kind) => switch (kind) {
  RecordKind.profile => l.profile,
  RecordKind.result => l.localResults,
  RecordKind.medication => l.localMedications,
  RecordKind.measurement => l.localMeasurements,
};
String valueKindTitle(AppLocalizations l, ResultValueKind kind) =>
    switch (kind) {
      ResultValueKind.numeric => l.localNumeric,
      ResultValueKind.comparison => l.localComparison,
      ResultValueKind.qualitative => l.localQualitative,
      ResultValueKind.missing => l.localMissing,
    };
String recordsErrorText(AppLocalizations l, RecordsError error) =>
    switch (error) {
      RecordsError.load => l.localLoadError,
      RecordsError.save => l.localSaveError,
      RecordsError.conflict => l.localConflict,
      RecordsError.invalid => l.localInvalid,
    };
