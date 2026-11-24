import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../results/results.dart';
import '../view_models/summary_view_model.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({
    required this.catalog,
    required this.onShowDoctor,
    super.key,
  });
  final DemoCatalog catalog;
  final VoidCallback onShowDoctor;
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final model = SummaryViewModel();
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = OrangePalette.of(context),
        d = widget.catalog;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => DemoPage(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cards = [
                _LatestVisit(catalog: d, onShowDoctor: widget.onShowDoctor),
                _VisitEvents(catalog: d),
              ];
              if (c.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19) {
                return Column(
                  children: [cards[0], const SizedBox(height: 10), cards[1]],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[1]),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SectionHeading(l.systemsHeading),
          const SizedBox(height: 8),
          TextField(
            key: const Key('system-search'),
            onChanged: model.search,
            decoration: InputDecoration(
              hintText: l.systemSearch,
              prefixIcon: const Icon(Icons.search, size: 19),
            ),
          ),
          const SizedBox(height: 12),
          PaperCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.shownSystems(model.visible.length, d.systems.length),
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _chooseSystems(context),
                      icon: const Icon(Icons.filter_list, size: 15),
                      label: Text(l.chooseSystems),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (var i = 0; i < d.sections.length; i++)
                      _SectionChip(
                        label: sectionTitle(context, i),
                        count:
                            '${d.sections[i].where(model.visible.contains).length}/${d.sections[i].length}',
                        color: OrangePalette.systemColors[i],
                        selected: d.sections[i].any(model.visible.contains),
                        onTap: () => model.toggleSection(d.sections[i]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showReferenceSheet(
                context,
                l.showHints,
                Text(l.sourceDisclaimer),
              ),
              child: Text(l.showHints),
            ),
          ),
          for (var section = 0; section < d.sections.length; section++)
            if (_systems(context, section).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 9),
                child: Wrap(
                  spacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: OrangePalette.systemColors[section],
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      sectionTitle(context, section),
                      style: TextStyle(
                        color: OrangePalette.systemColors[section],
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.withData(
                        d.sections[section]
                            .where((id) => d.systems[id].results.isNotEmpty)
                            .length,
                        d.sections[section].length,
                      ),
                      style: TextStyle(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ),
              AdaptiveTiles(
                children: [
                  for (final system in _systems(context, section))
                    _SystemTile(system: system, section: section, catalog: d),
                ],
              ),
            ],
          if (List.generate(
            d.sections.length,
            (i) => _systems(context, i),
          ).every((a) => a.isEmpty))
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.noMatches),
            ),
          const SizedBox(height: 20),
          PaperCard(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => showHistory(context, d),
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: p.accent, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.fullHistory,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l.historySub,
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.sourceDisclaimer,
            style: TextStyle(color: p.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  List<DemoSystem> _systems(BuildContext context, int section) => widget
      .catalog
      .sections[section]
      .where(model.visible.contains)
      .map((id) => widget.catalog.systems[id])
      .where(
        (s) =>
            model.query.isEmpty ||
            '${systemTitle(context, s.id)} ${systemSubtitle(context, s.id)} ${s.results.map((r) => r.name).join(' ')}'
                .toLowerCase()
                .contains(model.query),
      )
      .toList();
  Future<void> _chooseSystems(BuildContext context) {
    final l = AppLocalizations.of(context),
        selected = Set<int>.of(model.visible);
    return showReferenceSheet(
      context,
      l.chooseSystems,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            for (var i = 0; i < widget.catalog.systems.length; i++)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(systemTitle(context, i)),
                value: selected.contains(i),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.add(i);
                  } else {
                    selected.remove(i);
                  }
                }),
              ),
            FilledButton(
              onPressed: () {
                model.selectSystems(selected);
                Navigator.of(context).pop();
              },
              child: Text(l.chooseSystems),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestVisit extends StatelessWidget {
  const _LatestVisit({required this.catalog, required this.onShowDoctor});
  final DemoCatalog catalog;
  final VoidCallback onShowDoctor;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final labels = [l.inRange, l.outOfRange, l.notRecently, l.allResults];
    return PaperCard(
      padding: const EdgeInsets.all(10),
      stripe: const Color(0xFF7956D9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisitHeader(
            title: l.latestVisit,
            subtitle: '${catalog.dates.last} · ${catalog.labs.last}',
            icon: Icons.schedule,
            color: p.accent,
          ),
          const SizedBox(height: 10),
          const Divider(),
          InkWell(
            onTap: () => showComparison(context, catalog),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.visitCompare(catalog.dates[catalog.dates.length - 2]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 15, color: p.accent),
                ],
              ),
            ),
          ),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Material(
                color: p.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: p.line),
                ),
                child: InkWell(
                  onTap: () => showResultFilter(context, catalog, i),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labels[i],
                            style: const TextStyle(fontSize: 11.5, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${catalog.counts[i]}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: i == 0
                                ? p.green
                                : i == 1
                                ? p.red
                                : p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 2),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6944BE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onPressed: onShowDoctor,
            child: Text(l.showDoctor, style: const TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _VisitHeader extends StatelessWidget {
  const _VisitHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: OrangePalette.of(context).secondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _VisitEvents extends StatelessWidget {
  const _VisitEvents({required this.catalog});
  final DemoCatalog catalog;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return PaperCard(
      padding: const EdgeInsets.all(10),
      stripe: const Color(0xFFE8590C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisitHeader(
            title: l.visitEvents,
            subtitle: l.eventCount(catalog.eventLabels.length),
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFFC65B17),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < catalog.eventLabels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Tooltip(
                message: catalog.eventLabels[i],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0 ? p.orangeSoft : p.accentSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        i == 0
                            ? Icons.warning_amber_rounded
                            : i == 1
                            ? Icons.device_thermostat_outlined
                            : i < 4
                            ? Icons.chat_bubble_outline
                            : Icons.medication_outlined,
                        size: 12,
                        color: i == 0 ? const Color(0xFFE8590C) : p.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          catalog.eventLabels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => showReferenceSheet(
              context,
              l.visitEvents,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final text in catalog.eventLabels)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(text),
                    ),
                ],
              ),
            ),
            child: Text(l.moreEvents),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: p.orangeSoft,
              foregroundColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF893900)
                  : const Color(0xFFFFBE88),
              side: const BorderSide(color: Color(0xFFEAB387)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onPressed: () => showUnavailable(context, l.addEvent),
            child: Text(l.addEvent, style: const TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label, count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .055) : Colors.transparent,
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.45 : 0.15),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 10,
                color: OrangePalette.of(context).muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SystemTile extends StatelessWidget {
  const _SystemTile({
    required this.system,
    required this.section,
    required this.catalog,
  });
  final DemoSystem system;
  final int section;
  final DemoCatalog catalog;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final abnormal = system.results
        .where((r) => r.status == 'high' || r.status == 'low')
        .length;
    final empty = system.results.isEmpty;
    return ColorTile(
      title: systemTitle(context, system.id),
      subtitle: systemSubtitle(context, system.id),
      icon: SvgPicture.asset('assets/icons/${system.icon}.svg'),
      color: OrangePalette.systemColors[section],
      empty: empty,
      onTap: () => showSystemResults(context, catalog, system),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            empty
                ? l.notUploaded
                : '${l.resultCount(system.results.length)} · ${system.results.first.current?.date ?? '—'}',
            style: TextStyle(fontSize: 10.5, color: p.muted),
          ),
          const SizedBox(height: 6),
          StatusPill(
            label: empty
                ? l.noData
                : abnormal > 0
                ? l.abnormalCount(abnormal)
                : l.allNormal,
            color: empty
                ? p.muted
                : abnormal > 0
                ? p.red
                : p.green,
            background: empty
                ? p.paper
                : abnormal > 0
                ? p.redSoft
                : p.greenSoft,
          ),
        ],
      ),
    );
  }
}
