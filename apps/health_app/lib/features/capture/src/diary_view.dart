import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/reference_widgets.dart';
import '../../../presentation/calendar_input.dart';
import 'diary_view_model.dart';

Future<void> showMeasurementDiary(
  BuildContext context, {
  required String profileId,
  required CalendarDate today,
  required String Function() newId,
  required Future<bool> Function(List<HealthRecord>, String) save,
  List<HomeMeasurement> entries = const [],
}) async {
  final l = AppLocalizations.of(context);
  final model = DiaryViewModel(
    profileId: profileId,
    entries: entries,
    today: today,
    newId: newId,
    save: save,
    names: {
      DiaryKind.glucose: [l.diaryGlucose],
      DiaryKind.pressure: [l.diarySystolic, l.diaryDiastolic],
      DiaryKind.sleep: [l.diarySleep],
    },
    units: const {
      DiaryKind.glucose: ['mmol/L'],
      DiaryKind.pressure: ['mmHg', 'mmHg'],
      DiaryKind.sleep: ['h'],
    },
  );
  try {
    await showReferenceSheet(
      context,
      l.measurementDiary,
      _DiaryView(model: model, entries: entries),

      maxWidth: 600,
    );
  } finally {
    model.dispose();
  }
}

class _DiaryView extends StatefulWidget {
  const _DiaryView({required this.model, required this.entries});
  final DiaryViewModel model;
  final List<HomeMeasurement> entries;
  @override
  State<_DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends State<_DiaryView> {
  late final _date = TextEditingController(text: widget.model.date);
  late final _time = TextEditingController(text: widget.model.time);
  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  Widget field(
    String key,
    String label,
    String initial,
    ValueChanged<String> set, {
    String? hint,
  }) => Padding(
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
          key: ValueKey(
            'diary-${widget.model.generation}-${widget.model.kind.name}-$key',
          ),
          controller: key == 'date'
              ? _date
              : key == 'time'
              ? _time
              : null,
          initialValue: key == 'date' || key == 'time' ? null : initial,
          enabled: !widget.model.saving,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: key == 'date'
                ? IconButton(
                    tooltip: AppLocalizations.of(context).chooseDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    onPressed: widget.model.saving
                        ? null
                        : () async {
                            final value = await pickCalendarDate(
                              context,
                              _date.text,
                            );
                            if (value != null) {
                              _date.text = value;
                              widget.model.date = value;
                              widget.model.changed();
                            }
                          },
                  )
                : key == 'time'
                ? IconButton(
                    tooltip: AppLocalizations.of(context).chooseTime,
                    icon: const Icon(Icons.schedule, size: 17),
                    onPressed: widget.model.saving
                        ? null
                        : () async {
                            final value = await pickLocalTime(
                              context,
                              _time.text,
                            );
                            if (value != null) {
                              _time.text = value;
                              widget.model.time = value;
                              widget.model.changed();
                            }
                          },
                  )
                : null,
            filled: true,
            fillColor: OrangePalette.of(context).paper,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
          ),
          onChanged: (v) {
            set(v);
            widget.model.changed();
          },
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model,
          l = AppLocalizations.of(context),
          p = OrangePalette.of(context);
      final entries =
          m.entries.where((e) => e.source == diarySource(m.kind)).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<DiaryKind>(
              initialValue: m.kind,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontSize: 13),
              decoration: InputDecoration(labelText: l.diaryWhat),
              items: [
                for (final k in DiaryKind.values)
                  DropdownMenuItem(
                    value: k,
                    child: Text(switch (k) {
                      DiaryKind.glucose => l.diaryGlucose,
                      DiaryKind.pressure => l.diaryPressure,
                      DiaryKind.sleep => l.diarySleep,
                    }),
                  ),
              ],
              onChanged: m.saving ? null : (v) => m.select(v!),
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final fields = [
                Expanded(
                  child: field(
                    'date',
                    l.dateLabel,
                    m.date,
                    (v) => m.date = v,
                    hint: l.localDateHint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: field(
                    'time',
                    l.localTime,
                    m.time,
                    (v) => m.time = v,
                    hint: 'HH:MM',
                  ),
                ),
              ];
              return c.maxWidth > 290 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.5
                  ? Row(children: fields)
                  : Column(
                      children: [
                        field(
                          'date',
                          l.dateLabel,
                          m.date,
                          (v) => m.date = v,
                          hint: l.localDateHint,
                        ),
                        field(
                          'time',
                          l.localTime,
                          m.time,
                          (v) => m.time = v,
                          hint: 'HH:MM',
                        ),
                      ],
                    );
            },
          ),
          if (m.time.isNotEmpty || m.offset.isNotEmpty) ...[
            field(
              'offset',
              l.localOffset,
              m.offset,
              (v) => m.offset = v,
              hint: '+03:00',
            ),
            Text(
              l.localTimeHint,
              style: TextStyle(color: p.secondary, fontSize: 12),
            ),
          ],
          field(
            'first',
            switch (m.kind) {
              DiaryKind.glucose => l.diaryGlucoseValue,
              DiaryKind.pressure => l.diarySystolic,
              DiaryKind.sleep => l.diarySleepValue,
            },
            m.first,
            (v) => m.first = v,
          ),
          if (m.kind == DiaryKind.pressure)
            field('second', l.diaryDiastolic, m.second, (v) => m.second = v),
          if (m.invalid) Text(l.localInvalid, style: TextStyle(color: p.red)),
          if (m.failed) Text(l.localSaveError, style: TextStyle(color: p.red)),
          FilledButton(
            onPressed: m.saving
                ? null
                : () async {
                    await m.submit();
                  },
            child: Text(l.diarySave),
          ),
          const SizedBox(height: 20),
          Text(
            l.diaryEntries,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty) Text(l.diaryEmpty),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${e.date}${e.minuteOfDay == null ? '' : ' ${(e.minuteOfDay! ~/ 60).toString().padLeft(2, '0')}:${(e.minuteOfDay! % 60).toString().padLeft(2, '0')}'} · ${e.name} — ${e.value.raw} ${e.unit}',
              ),
            ),
        ],
      );
    },
  );
}
