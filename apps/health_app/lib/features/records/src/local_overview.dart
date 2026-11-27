import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/reference_widgets.dart';
import 'records_view_model.dart';

/// Presentation of confirmed local data. No demo status or clinical expiry is
/// inferred from a raw value; medical series remain the core report's concern.
class LocalOverview extends StatelessWidget {
  const LocalOverview({
    required this.model,
    required this.onAddEvent,
    this.onHistory,
    super.key,
  });
  final RecordsViewModel model;
  final VoidCallback onAddEvent;
  final VoidCallback? onHistory;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final results =
        model
            .ofKind(RecordKind.result)
            .map((e) => e.record as LabResult)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final profile = model.profile?.record as MedicalProfile?;
    final events = profile?.details?.events ?? [];
    final medications = model
        .ofKind(RecordKind.medication)
        .map((e) => e.record as MedicationCourse)
        .toList();
    final cards = [
      PaperCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_outlined, color: p.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.latestVisit,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              results.isEmpty
                  ? l.localEmpty
                  : '${results.first.date} · ${results.first.laboratory}',
              style: const TextStyle(fontSize: 12),
            ),
            const Divider(),
            Text(
              l.resultCount(results.length),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l.reportNoInterpretation,
              style: TextStyle(fontSize: 12, color: p.secondary),
            ),
          ],
        ),
      ),
      PaperCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_outlined,
                  color: const Color(0xFF893900),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.visitEvents,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            for (final title in [
              ...events.map((e) => e.name),
              ...medications
                  .where((r) => r.activeOn(model.today))
                  .map((r) => r.name),
            ].take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (events.isEmpty && medications.isEmpty)
              Text(
                l.historyNoEvents,
                style: TextStyle(fontSize: 12, color: p.secondary),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAddEvent, child: Text(l.addShort)),
            ),
          ],
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) =>
              c.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4
              ? Column(
                  children: [cards[0], const SizedBox(height: 10), cards[1]],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 10),
                      Expanded(child: cards[1]),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('open-local-report'),
            onPressed: onHistory,
            icon: const Icon(Icons.table_chart_outlined, size: 17),
            label: Text(l.analysisHistory),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeading(l.systemsHeading),
        const SizedBox(height: 8),
      ],
    );
  }
}
