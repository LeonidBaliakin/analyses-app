import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../../presentation/calendar_input.dart';
import '../view_models/profile_editor_view_model.dart';
import 'profile_field_labels.dart';

Future<void> showProfileSectionEditor(
  BuildContext context, {
  required String title,
  required ProfileSection section,
  required MedicalProfile profile,
  required Future<bool> Function(MedicalProfile, String) save,
  required String Function() newId,
}) async {
  final model = ProfileEditorViewModel(
    profile: profile,
    saveProfile: save,
    newId: newId,
  );
  try {
    await showReferenceSheet(
      context,
      title,
      _ProfileEditor(model: model, section: section),
    );
  } finally {
    model.dispose();
  }
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.model, required this.section});
  final ProfileEditorViewModel model;
  final ProfileSection section;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _eventName = TextEditingController(),
      _start = TextEditingController(),
      _end = TextEditingController();
  late final _birth = TextEditingController(text: widget.model.birthDate);
  final _dateInputs = <String, TextEditingController>{};
  final _extra = <ProfileEventField, TextEditingController>{};
  @override
  void dispose() {
    for (final c in [
      _birth,
      _eventName,
      _start,
      _end,
      ..._dateInputs.values,
      ..._extra.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _label(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
  InputDecoration _decoration(BuildContext context) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: OrangePalette.of(context).paper,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
  Widget _select(
    BuildContext context,
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) {
    final all = [
      ('', AppLocalizations.of(context).profileNotStated),
      ...options,
    ];
    if (!all.any((o) => o.$1 == value)) all.add((value, value));
    return _label(
      label,
      DropdownButtonFormField<String>(
        initialValue: value,
        key: ValueKey('$label:$value'),
        isExpanded: true,
        decoration: _decoration(context),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        items: [
          for (final o in all)
            DropdownMenuItem(
              value: o.$1,
              child: Text(o.$2, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: widget.model.saving ? null : (v) => onChanged(v ?? ''),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    ProfileField field, {
    List<(String, String)>? options,
    bool multiline = false,
  }) {
    final m = widget.model,
        label = profileFieldLabel(AppLocalizations.of(context), field);
    if (options != null) {
      return _select(
        context,
        label,
        m.value(field),
        options,
        (v) => m.setField(field, v),
      );
    }
    final isDate =
        field == ProfileField.smokingQuitDate ||
        field == ProfileField.alcoholQuitDate;
    final dateInput = isDate
        ? _dateInputs.putIfAbsent(
            field.name,
            () => TextEditingController(text: m.value(field)),
          )
        : null;
    return _label(
      label,
      TextFormField(
        key: ValueKey(field),
        controller: dateInput,
        initialValue: isDate ? null : m.value(field),
        enabled: !m.saving,
        maxLines: multiline ? 3 : 1,
        decoration: _decoration(context).copyWith(
          suffixIcon: !isDate
              ? null
              : IconButton(
                  tooltip: AppLocalizations.of(context).chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  onPressed: m.saving
                      ? null
                      : () async {
                          final value = await pickCalendarDate(
                            context,
                            dateInput!.text,
                          );
                          if (value != null) {
                            dateInput.text = value;
                            m.setField(field, value);
                          }
                        },
                ),
        ),
        onChanged: (v) => m.setField(field, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model,
          l = AppLocalizations.of(context),
          p = OrangePalette.of(context);
      final base = widget.section == ProfileSection.base,
          life = widget.section == ProfileSection.lifestyle,
          history = widget.section == ProfileSection.history;
      final eventKind = switch (widget.section) {
        ProfileSection.complaints => ProfileEventKind.complaint,
        ProfileSection.illness => ProfileEventKind.illness,
        ProfileSection.hospitalization => ProfileEventKind.hospitalization,
        ProfileSection.allergy => ProfileEventKind.allergy,
        _ => null,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (base) ...[
            _field(
              context,
              ProfileField.sex,
              options: [('m', l.profileSexMale), ('f', l.profileSexFemale)],
            ),
            _label(
              l.birthDate,
              TextFormField(
                key: const Key('profile-birth-date'),
                controller: _birth,
                enabled: !m.saving,
                decoration: _decoration(context).copyWith(
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: IconButton(
                    tooltip: l.chooseDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    onPressed: m.saving
                        ? null
                        : () async {
                            final value = await pickCalendarDate(
                              context,
                              _birth.text,
                            );
                            if (value != null) {
                              _birth.text = value;
                              m.birthDate = value;
                              m.changed();
                            }
                          },
                  ),
                ),
                onChanged: (v) {
                  m.birthDate = v;
                  m.changed();
                },
              ),
            ),
            _field(context, ProfileField.height),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: p.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.profileOptionalMeasures,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final f in [
                    ProfileField.waist,
                    ProfileField.hips,
                    ProfileField.chest,
                  ])
                    _field(context, f),
                ],
              ),
            ),
            if (m.value(ProfileField.sex) == 'f')
              _field(context, ProfileField.cycle),
          ],
          if (life) ...[
            _field(context, ProfileField.city),
            _field(context, ProfileField.travel),
            _field(
              context,
              ProfileField.activity,
              options: [
                ('1', l.profileActivity1),
                ('2', l.profileActivity2),
                ('3', l.profileActivity3),
                ('4', l.profileActivity4),
              ],
            ),
            _field(context, ProfileField.sport),
            _field(context, ProfileField.foodNotes, multiline: true),
            _field(
              context,
              ProfileField.stress,
              options: [
                ('no', l.profileNo),
                ('sometimes', l.profileSometimes),
                ('often', l.profileOften),
              ],
            ),
            _field(context, ProfileField.sleep),
            _field(
              context,
              ProfileField.diet,
              options: [
                ('regular', l.profileDietNormal),
                ('vegetarian', l.profileDietVegetarian),
                ('vegan', l.profileDietVegan),
                ('keto', l.profileDietKeto),
                ('fasting', l.profileDietFasting),
              ],
            ),
            _field(
              context,
              ProfileField.smoking,
              options: [
                ('never', l.profileNeverSmoked),
                ('current', l.profileSmokes),
                ('former', l.profileFormerSmoker),
              ],
            ),
            if (m.value(ProfileField.smoking) != 'never')
              _field(
                context,
                ProfileField.packsPerDay,
                options: [
                  ('0.5', l.profilePacksHalf),
                  for (var i = 1; i <= 10; i++) ('$i', '$i'),
                ],
              ),
            if (m.value(ProfileField.smoking) == 'former')
              ..._quit(
                context,
                ProfileField.smokingQuitPrecision,
                ProfileField.smokingQuitDate,
                ProfileField.smokingQuitYear,
              ),
            _field(
              context,
              ProfileField.alcohol,
              options: [
                ('never', l.profileNoAlcohol),
                ('former', l.profileFormerDrinker),
                ('rare', l.profileAlcoholRare),
                ('weekly', l.profileAlcoholWeekly),
                ('often', l.profileAlcoholOften),
              ],
            ),
            if (m.value(ProfileField.alcohol) != 'never')
              _field(context, ProfileField.alcoholAmount),
            if (m.value(ProfileField.alcohol) == 'former')
              ..._quit(
                context,
                ProfileField.alcoholQuitPrecision,
                ProfileField.alcoholQuitDate,
                ProfileField.alcoholQuitYear,
              ),
          ],
          if (history)
            for (final kind in ProfileHistoryKind.values) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: p.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      [
                        l.profileChronic,
                        l.profileSurgery,
                        l.profileFamily,
                        l.profileOtherHistory,
                      ][kind.index],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final entry in m.history.where((e) => e.kind == kind))
                      _historyEntry(context, entry),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: m.saving ? null : () => m.addHistory(kind),
                        child: Text(l.profileAddRecord),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          if (eventKind != null) ...[
            for (final event in m.events.where((e) => e.kind == eventKind))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                                  event.start?.toString(),
                                  event.end?.toString(),
                                  ...event.fields.values,
                                ]
                                .whereType<String>()
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            style: TextStyle(fontSize: 12, color: p.secondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l.profileRemoveEntry,
                      onPressed: m.saving
                          ? null
                          : () => m.removeEvent(event.id),
                      icon: const Icon(Icons.close, size: 17),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SectionHeading(l.profileAddRecord),
            const SizedBox(height: 10),
            _label(
              l.profileEventName,
              TextField(
                key: const Key('profile-event-name'),
                controller: _eventName,
                decoration: _decoration(context),
              ),
            ),
            if (eventKind != ProfileEventKind.allergy) ...[
              _label(
                l.profileFrom,
                TextField(
                  controller: _start,
                  decoration: _decoration(context).copyWith(
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      tooltip: l.chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 17),
                      onPressed: () async {
                        final value = await pickCalendarDate(
                          context,
                          _start.text,
                        );
                        if (value != null) _start.text = value;
                      },
                    ),
                  ),
                ),
              ),
              if (eventKind != ProfileEventKind.complaint)
                _label(
                  l.profileTo,
                  TextField(
                    controller: _end,
                    decoration: _decoration(context).copyWith(
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: IconButton(
                        tooltip: l.chooseDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 17,
                        ),
                        onPressed: () async {
                          final value = await pickCalendarDate(
                            context,
                            _end.text,
                          );
                          if (value != null) _end.text = value;
                        },
                      ),
                    ),
                  ),
                ),
            ],
            for (final (field, label) in [
              if (eventKind == ProfileEventKind.illness)
                (ProfileEventField.temperature, l.profileTemperature),
              if (eventKind == ProfileEventKind.hospitalization) ...[
                (ProfileEventField.institution, l.profileInstitution),
                (ProfileEventField.outcomes, l.profileOutcomes),
              ],
              if (eventKind == ProfileEventKind.allergy)
                (ProfileEventField.reaction, l.profileReaction),
            ])
              _label(
                label,
                TextField(
                  controller: _extra.putIfAbsent(
                    field,
                    TextEditingController.new,
                  ),
                  decoration: _decoration(context),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('profile-event-add'),
                onPressed: m.saving
                    ? null
                    : () async {
                        if (await m.addEvent(
                          kind: eventKind,
                          name: _eventName.text,
                          start: _start.text,
                          end: _end.text,
                          fields: {
                            for (final e in _extra.entries) e.key: e.value.text,
                          },
                        )) {
                          _eventName.clear();
                          _start.clear();
                          _end.clear();
                          for (final c in _extra.values) {
                            c.clear();
                          }
                        }
                      },
                child: Text(l.profileAdd),
              ),
            ),
          ],
          if (m.invalid || m.failed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  m.invalid ? l.localValueInvalid : l.localSaveError,
                  style: TextStyle(color: p.red),
                ),
              ),
            ),
          if (m.saving) const LinearProgressIndicator(),
          if (base || life || history)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('profile-save'),
                onPressed: m.saving
                    ? null
                    : () async {
                        if (await m.save() && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(l.profileSave),
              ),
            ),
        ],
      );
    },
  );
  List<Widget> _quit(
    BuildContext context,
    ProfileField precision,
    ProfileField date,
    ProfileField year,
  ) {
    final m = widget.model, l = AppLocalizations.of(context);
    return [
      _field(
        context,
        precision,
        options: [
          ('unknown', l.profileUnknownDate),
          ('date', l.profileExactDate),
          ('year', l.profileApproximateYear),
        ],
      ),
      if (m.value(precision) == 'date') _field(context, date),
      if (m.value(precision) == 'year') _field(context, year),
    ];
  }

  Widget _historyEntry(BuildContext context, HistoryEntryDraft e) {
    final l = AppLocalizations.of(context), m = widget.model;
    return Padding(
      key: ValueKey(e.id),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(
            l.profileDescription,
            TextFormField(
              initialValue: e.text,
              maxLines: 2,
              decoration: _decoration(context),
              onChanged: (v) {
                e.text = v;
                m.changed();
              },
            ),
          ),
          _select(
            context,
            l.profileWhen,
            e.precision.name,
            [
              for (final p in HistoryDatePrecision.values)
                (
                  p.name,
                  [
                    l.profileUnknownDate,
                    l.profileExactDate,
                    l.profileApproximateYear,
                    l.profileChildhood,
                  ][p.index],
                ),
            ],
            (v) {
              e.precision = HistoryDatePrecision.values.byName(
                v.isEmpty ? 'unknown' : v,
              );
              m.updateHistory();
            },
          ),
          if (e.precision == HistoryDatePrecision.date)
            _label(
              l.profileExactDate,
              TextFormField(
                controller: _dateInputs.putIfAbsent(
                  e.id,
                  () => TextEditingController(text: e.date),
                ),
                decoration: _decoration(context).copyWith(
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: IconButton(
                    tooltip: l.chooseDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    onPressed: m.saving
                        ? null
                        : () async {
                            final value = await pickCalendarDate(
                              context,
                              e.date,
                            );
                            if (value != null) {
                              _dateInputs[e.id]!.text = value;
                              e.date = value;
                              m.changed();
                            }
                          },
                  ),
                ),
                onChanged: (v) {
                  e.date = v;
                  m.changed();
                },
              ),
            ),
          if (e.precision == HistoryDatePrecision.year ||
              e.precision == HistoryDatePrecision.childhood)
            _label(
              l.profileApproximateYear,
              TextFormField(
                initialValue: e.year,
                keyboardType: TextInputType.number,
                decoration: _decoration(context),
                onChanged: (v) {
                  e.year = v;
                  m.changed();
                },
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: m.saving ? null : () => m.removeHistory(e.id),
              child: Text(l.profileRemoveEntry),
            ),
          ),
        ],
      ),
    );
  }
}
