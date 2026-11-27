import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../results/results.dart';
import '../../../profile/profile.dart';
import '../view_models/summary_view_model.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({
    required this.catalog,
    required this.onOpenHistory,
    this.onStartIntroduction,
    this.onPrintSystems,
    this.onAddEvent,
    super.key,
  });
  final DemoCatalog catalog;
  final VoidCallback onOpenHistory;
  final ValueChanged<Set<int>>? onPrintSystems;
  final VoidCallback? onStartIntroduction, onAddEvent;
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
                _LatestVisit(catalog: d, width: (c.maxWidth - 10) / 2 - 22),
                _VisitEvents(catalog: d, onAddEvent: widget.onAddEvent),
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
          SpotlightAnchor(
            id: 'analysis-history',
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('open-analysis-history'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: p.accentSoft,
                  foregroundColor: p.accent,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: widget.onOpenHistory,
                icon: const Icon(Icons.table_chart_outlined, size: 17),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(l.analysisHistory)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.shownSystems(model.visible.length, d.systems.length),
                      style: TextStyle(fontSize: 12.5, color: p.secondary),
                    ),
                    FilledButton.icon(
                      key: const Key('choose-systems'),
                      onPressed: () => _choose(context),
                      icon: const Icon(Icons.filter_list, size: 15),
                      label: Text(l.chooseSystems),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < d.sections.length; i++)
                        _SectionChip(
                          label: sectionTitle(context, i),
                          count: d.sections[i]
                              .where(model.visible.contains)
                              .length,
                          total: d.sections[i].length,
                          color: OrangePalette.systemColors[i],
                          onTap: () => model.toggleSection(d.sections[i]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onStartIntroduction,
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
                        color: p.ink,
                        fontSize: 14,
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
                    Stack(
                      children: [
                        _SystemTile(
                          system: system,
                          section: section,
                          catalog: d,
                          onTap: model.selecting
                              ? () => model.togglePrintSystem(system.id)
                              : null,
                        ),
                        if (model.selecting)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Checkbox(
                              value: model.printSystems.contains(system.id),
                              onChanged: (_) =>
                                  model.togglePrintSystem(system.id),
                            ),
                          ),
                      ],
                    ),
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
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: model.togglePrinting,
                child: Text(model.selecting ? l.localCancel : l.selectPrint),
              ),
              if (model.selecting)
                FilledButton(
                  onPressed:
                      model.printSystems.isEmpty ||
                          widget.onPrintSystems == null
                      ? null
                      : () =>
                            widget.onPrintSystems!(model.printSystems.toSet()),
                  child: Text(
                    '${l.printSelected} (${model.printSystems.length})',
                  ),
                ),
            ],
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

  void _choose(BuildContext context) {
    final l = AppLocalizations.of(context);
    showReferenceSheet(
      context,
      l.chooseSystems,
      StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    model.selectSystems(
                      widget.catalog.systems.map((s) => s.id).toSet(),
                    );
                    update(() {});
                  },
                  child: Text(l.allSystems),
                ),
                TextButton(
                  onPressed: () {
                    model.selectSystems({});
                    update(() {});
                  },
                  child: Text(l.clearSelection),
                ),
              ],
            ),
            for (
              var section = 0;
              section < widget.catalog.sections.length;
              section++
            ) ...[
              Text(
                sectionTitle(context, section),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              for (final id in widget.catalog.sections[section])
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(systemTitle(context, id)),
                  value: model.visible.contains(id),
                  onChanged: (_) {
                    final ids = model.visible.toSet();
                    if (!ids.remove(id)) ids.add(id);
                    model.selectSystems(ids);
                    update(() {});
                  },
                ),
            ],
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.localSave),
            ),
          ],
        ),
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
}

class _LatestVisit extends StatelessWidget {
  const _LatestVisit({required this.catalog, required this.width});
  final double width;
  final DemoCatalog catalog;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final labels = [l.inRange, l.outOfRange, l.notRecently, l.allResults];
    return PaperCard(
      padding: const EdgeInsets.all(10),

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
          Wrap(
            spacing: 5,
            runSpacing: 0,
            children: [
              for (var i = 0; i < labels.length; i++)
                SizedBox(
                  width: MediaQuery.sizeOf(context).width > 540
                      ? (width - 5) / 2
                      : width,
                  child: Padding(
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
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
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
                ),
            ],
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
        width: MediaQuery.sizeOf(context).width <= 480 ? 25 : 38,
        height: MediaQuery.sizeOf(context).width <= 480 ? 25 : 38,
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
              style: TextStyle(
                fontSize: (MediaQuery.sizeOf(context).width * .026).clamp(
                  13,
                  19,
                ),
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
  const _VisitEvents({required this.catalog, this.onAddEvent});
  final DemoCatalog catalog;
  final VoidCallback? onAddEvent;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return PaperCard(
      padding: const EdgeInsets.all(10),

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
          for (
            var i = 0;
            i <
                (MediaQuery.sizeOf(context).width <= 540 ? 5 : 3).clamp(
                  0,
                  catalog.eventLabels.length,
                );
            i++
          )
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
                          maxLines: 2,
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
          const SizedBox(height: 10),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showDemoActivity(context, catalog),
                    child: Text(
                      '${l.moreEvents} ${catalog.eventLabels.length - (MediaQuery.sizeOf(context).width <= 540 ? 5 : 3)}',
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF913B0C),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed:
                    onAddEvent ?? () => showDemoEventCapture(context, catalog),
                child: Text(l.addShort, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemTile extends StatelessWidget {
  const _SystemTile({
    required this.system,
    required this.section,
    required this.catalog,
    this.onTap,
  });
  final VoidCallback? onTap;
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
      badge: [1, 8, 9, 12, 14, 15].contains(system.id)
          ? StatusPill(
              label: empty
                  ? (system.id == 14 ? l.validityMonth : l.validityFortnight)
                  : l.verifyHospitalValidity,
              color: empty ? p.secondary : const Color(0xFF963B0C),
              background: empty ? p.paper : p.orangeSoft,
            )
          : null,
      onTap: onTap ?? () => showSystemResults(context, catalog, system),
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

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int count, total;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return Semantics(
      checked: count > 0,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: count > 0 ? Color.lerp(p.card, color, .1) : p.card,
            border: Border.all(
              color: count > 0 ? Color.lerp(p.card, color, .45)! : p.line,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: count > 0 ? color : p.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count/$total',
                style: TextStyle(fontSize: 10, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
