import 'package:material_ui/material_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Reusable profile view. Persistence and record revisions stay with the caller.
class ProfileCoursesView extends StatelessWidget {
  const ProfileCoursesView({
    required this.courses,
    required this.onAdd,
    required this.onEdit,
    required this.onExperience,
    required this.onRemove,
    required this.today,
    this.addForm,
    super.key,
  });
  final Widget? addForm;
  final List<MedicationCourse> courses;
  final CalendarDate today;
  final VoidCallback onAdd;
  final ValueChanged<MedicationCourse> onEdit, onRemove;
  final void Function(MedicationCourse, MedicationExperience?) onExperience;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sorted = courses.toList()..sort((a, b) => b.start.compareTo(a.start));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (addForm == null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 17),
              label: Text(l.localAddMedication),
            ),
          ),
        const SizedBox(height: 14),
        if (sorted.isEmpty)
          Text(l.diaryEmpty)
        else if (MediaQuery.sizeOf(context).width <= 760)
          PaperCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [for (final r in sorted) _compact(context, r)],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 16,
              dataRowMinHeight: 80,
              dataRowMaxHeight: 160,
              columns: [
                DataColumn(label: Text(l.localDosage)),
                DataColumn(label: Text(l.medicationMode)),
                DataColumn(label: Text(l.profileFrom)),
                DataColumn(label: Text(l.profileTo)),
                DataColumn(label: Text(l.statusLabel)),
                const DataColumn(label: SizedBox.shrink()),
              ],
              rows: [
                for (final r in sorted)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (r.prescribedBy.isNotEmpty ||
                                  r.reason.isNotEmpty)
                                Text(
                                  [
                                    r.prescribedBy,
                                    r.reason,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              DropdownButton<MedicationExperience?>(
                                value: r.experience,
                                isExpanded: true,
                                hint: Text(l.medicationExperience),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(l.profileNotStated),
                                  ),
                                  for (final e in MedicationExperience.values)
                                    DropdownMenuItem(
                                      value: e,
                                      child: Text(switch (e) {
                                        MedicationExperience.firstCourse =>
                                          l.medicationFirstCourse,
                                        MedicationExperience.repeatCourse =>
                                          l.medicationRepeatCourse,
                                        MedicationExperience.unknown =>
                                          l.medicationUnknownCourse,
                                      }),
                                    ),
                                ],
                                onChanged: (v) => onExperience(r, v),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => onEdit(r),
                      ),
                      DataCell(
                        Text(
                          r.regimen == MedicationRegimen.ongoing
                              ? l.medicationConstant
                              : r.regimen == MedicationRegimen.course
                              ? l.medicationCourse
                              : l.profileNotStated,
                        ),
                      ),
                      DataCell(Text('${r.start}')),
                      DataCell(Text(r.end?.toString() ?? '—')),
                      DataCell(
                        Text(
                          r.start.compareTo(today) > 0
                              ? l.profileFrom
                              : r.end != null && r.end!.compareTo(today) < 0
                              ? l.medicationCompleted
                              : l.medicationActive,
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () => onRemove(r),
                          tooltip: l.profileRemoveEntry,
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        if (addForm != null) ...[
          const SizedBox(height: 18),
          Text(
            l.profileAddRecord,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          addForm!,
        ],
      ],
    );
  }

  Widget _compact(BuildContext context, MedicationCourse r) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    String date(CalendarDate? d) => d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${(d.year % 100).toString().padLeft(2, '0')}';
    final active = r.activeOn(today);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onEdit(r),
            child: Text(
              r.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          if (r.prescribedBy.isNotEmpty || r.reason.isNotEmpty)
            Text(
              [r.prescribedBy, r.reason].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(fontSize: 11, color: p.secondary),
            ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: DropdownButtonFormField<MedicationExperience?>(
              key: ValueKey('${r.id}:${r.experience}'),
              initialValue: r.experience,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontSize: 11, color: p.ink),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: p.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              hint: Text(
                l.medicationExperience,
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 11),
              ),
              items: [
                for (final e in MedicationExperience.values)
                  DropdownMenuItem(
                    value: e,
                    child: Text(switch (e) {
                      MedicationExperience.firstCourse =>
                        l.medicationFirstCourse,
                      MedicationExperience.repeatCourse =>
                        l.medicationRepeatCourse,
                      MedicationExperience.unknown => l.medicationUnknownCourse,
                    }),
                  ),
              ],
              onChanged: (v) => onExperience(r, v),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      r.regimen == MedicationRegimen.ongoing
                          ? l.medicationConstant
                          : r.regimen == MedicationRegimen.course
                          ? l.medicationCourse
                          : l.profileNotStated,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(date(r.start), style: const TextStyle(fontSize: 11)),
                    Text(date(r.end), style: const TextStyle(fontSize: 11)),
                    StatusPill(
                      label: active
                          ? l.medicationActive
                          : l.medicationCompleted,
                      color: active ? p.green : p.secondary,
                      background: active ? p.greenSoft : p.paper,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onRemove(r),
                tooltip: l.profileRemoveEntry,
                icon: const Icon(Icons.close, size: 14),
                style: IconButton.styleFrom(
                  minimumSize: const Size(30, 30),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
