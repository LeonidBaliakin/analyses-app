import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'history_models.dart';
import 'history_view_model.dart';

class AnalysisHistoryView extends StatefulWidget {
  const AnalysisHistoryView({
    required this.model,
    this.onClose,
    this.onOpenRow,
    this.onExport,
    this.onCopy,
    this.onShare,
    this.exporting = false,
    super.key,
  });
  final HistoryViewModel model;
  final VoidCallback? onClose, onExport, onCopy, onShare;
  final ValueChanged<HistoryRow>? onOpenRow;
  final bool exporting;
  @override
  State<AnalysisHistoryView> createState() => _AnalysisHistoryViewState();
}

class _AnalysisHistoryViewState extends State<AnalysisHistoryView> {
  final _horizontal = ScrollController(),
      _values = ScrollController(),
      _names = ScrollController();
  final _query = TextEditingController(),
      _start = TextEditingController(),
      _end = TextEditingController();
  bool _positioned = false;
  Orientation? _physicalOrientation;
  bool _searchOpen = false,
      _rotated = false,
      _syncing = false,
      _datesOpen = false;
  @override
  void initState() {
    super.initState();
    _query.text = widget.model.query;
    _syncDates();
    _values.addListener(() => _syncScroll(_values, _names));
    _names.addListener(() => _syncScroll(_names, _values));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (_physicalOrientation != null && _physicalOrientation != orientation) {
      _rotated = false;
    }
    _physicalOrientation = orientation;
    if (!_positioned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _horizontal.hasClients) {
          _horizontal.jumpTo(_horizontal.position.maxScrollExtent);
          _positioned = true;
        }
      });
    }
  }

  void _syncDates() {
    _start.text = widget.model.period.start.toString();
    _end.text = widget.model.period.end.toString();
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (_syncing || !target.hasClients) return;
    _syncing = true;
    target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
    _syncing = false;
  }

  @override
  void dispose() {
    for (final controller in [_horizontal, _values, _names]) {
      controller.dispose();
    }
    for (final controller in [_query, _start, _end]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _pan(double direction) {
    if (_horizontal.hasClients) {
      _horizontal.animateTo(
        (_horizontal.offset + direction * 240).clamp(
          0,
          _horizontal.position.maxScrollExtent,
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => UnobstructedPane(
      child: LayoutBuilder(
        builder: (context, constraints) => RotatedBox(
          quarterTurns: _rotated ? 1 : 0,
          child: _content(context),
        ),
      ),
    ),
  );

  Widget _period(BuildContext context, bool compact) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    final labels = [
      l.latestVisit,
      l.historyRecent,
      l.historyAll,
      l.historyCustom,
    ];
    return PopupMenuButton<HistoryPeriod>(
      key: const Key('history-period'),
      tooltip: '${l.historyPeriod}: ${labels[m.periodKind.index]}',
      initialValue: m.periodKind,
      onSelected: (value) {
        if (value == HistoryPeriod.custom) {
          setState(() => _datesOpen = true);
        } else {
          m.selectPeriod(value);
          _syncDates();
          setState(() => _datesOpen = false);
        }
      },
      itemBuilder: (_) => [
        for (final value in HistoryPeriod.values)
          PopupMenuItem(value: value, child: Text(labels[value.index])),
      ],
      child: Container(
        constraints: BoxConstraints(maxWidth: compact ? 150 : 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: p.card,
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                labels[m.periodKind.index],
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    return Material(
      color: p.card,
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth <= 590 || (_rotated && c.maxHeight < 590);
          Widget action(
            IconData icon,
            String tooltip,
            VoidCallback? onTap, {
            Key? key,
            bool active = false,
          }) => IconButton(
            key: key,
            tooltip: tooltip,
            onPressed: onTap,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(7),
              foregroundColor: active ? Colors.white : p.accent,
              backgroundColor: active ? p.accent : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: Icon(icon, size: 18),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: p.accentSoft,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        compact ? l.historyShort : l.analysisHistory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!compact)
                      Text(
                        '${m.rows.length} / ${m.data.rows.length} · ${m.dates.length}',
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                    if (m.selected.isNotEmpty)
                      action(Icons.restart_alt, l.historyReset, () {
                        m.reset();
                        _query.clear();
                        _syncDates();
                      }),
                    _period(context, compact),
                    action(
                      Icons.screen_rotation_outlined,
                      l.historyRotate,
                      () => setState(() => _rotated = !_rotated),
                      key: const Key('history-rotate'),
                    ),
                    action(Icons.close, l.close, widget.onClose),
                  ],
                ),
              ),
              if (_datesOpen)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      for (final pair in [
                        (_start, l.reportFrom, 'report-from'),
                        (_end, l.reportTo, 'report-to'),
                      ]) ...[
                        Expanded(
                          child: TextField(
                            key: Key(pair.$3),
                            controller: pair.$1,
                            onChanged: (_) =>
                                m.setPeriod(_start.text, _end.text),
                            decoration: InputDecoration(
                              labelText: pair.$2,
                              hintText: 'YYYY-MM-DD',
                              errorText: m.invalidPeriod
                                  ? l.reportInvalid
                                  : null,
                            ),
                          ),
                        ),
                        if (pair.$3 == 'report-from') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                child: InkWell(
                  onTap: m.toggleEvents,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.accentSoft.withValues(alpha: .5),
                      border: Border.all(color: p.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m.showEvents
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          size: 15,
                          color: p.accent,
                        ),
                        Expanded(
                          child: Text(
                            '${l.historyPeriodEvents} · ${m.events.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, body) => Column(
                          children: [
                            Offstage(
                              offstage: !m.showEvents || body.maxHeight < 180,
                              child: SizedBox(
                                height: math.min(
                                  220,
                                  math.max(48, body.maxHeight * .30),
                                ),
                                child: _EventTimeline(model: m),
                              ),
                            ),
                            Expanded(
                              child: m.rows.isEmpty
                                  ? Center(child: Text(l.historyEmpty))
                                  : _table(
                                      context,
                                      Size(c.maxWidth, c.maxHeight),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_searchOpen)
                      Positioned(
                        right: 8,
                        bottom: 4,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.min(360, c.maxWidth - 16),
                            maxHeight: math.max(90, c.maxHeight * .55),
                          ),
                          child: _search(context),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  border: Border(top: BorderSide(color: p.line)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  children: [
                    action(
                      Icons.show_chart,
                      l.historyEvents,
                      () {
                        setState(() => _searchOpen = false);
                        m.toggleEvents();
                      },
                      key: const Key('history-events-toggle'),
                      active: m.showEvents,
                    ),
                    PopupMenuButton<int>(
                      tooltip: l.historyLegend,
                      position: PopupMenuPosition.over,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            '↑ ${l.aboveRange}',
                            style: TextStyle(color: p.red),
                          ),
                        ),
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            '↓ ${l.belowRange}',
                            style: TextStyle(color: p.blue),
                          ),
                        ),
                        PopupMenuItem(
                          enabled: false,
                          child: Text('— ${l.noData}'),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.info_outline,
                          size: 17,
                          color: p.accent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    action(
                      Icons.arrow_back,
                      l.historyScrollBack,
                      () => _pan(-1),
                    ),
                    action(
                      Icons.arrow_forward,
                      l.historyScrollForward,
                      () => _pan(1),
                    ),
                    const Spacer(),
                    if (widget.onExport != null || widget.onShare != null)
                      PopupMenuButton<int>(
                        key: const Key('history-export'),
                        tooltip: l.historyPdfActions,
                        position: PopupMenuPosition.over,
                        enabled: !m.invalidPeriod && !widget.exporting,
                        onSelected: (value) {
                          if (value == 0) {
                            (widget.onExport ?? widget.onCopy)?.call();
                          } else {
                            (widget.onShare ?? widget.onExport)?.call();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 0,
                            child: Text(l.historySavePdf),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Text(l.historySharePdf),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'PDF',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.25,
                                  color: p.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 12),
                            ],
                          ),
                        ),
                      ),
                    if (widget.onExport == null &&
                        widget.onShare == null &&
                        widget.onCopy != null)
                      action(
                        Icons.copy,
                        l.reportCopy,
                        widget.onCopy,
                        key: const Key('copy-local-report'),
                      ),
                    action(
                      Icons.search,
                      _searchOpen ? l.close : l.historySearch,
                      () => setState(() => _searchOpen = !_searchOpen),
                      key: const Key('history-search-toggle'),
                      active: true,
                    ),
                  ],
                ),
              ),
            ],
          );
          return c.maxHeight < 260
              ? SingleChildScrollView(
                  child: SizedBox(height: 460, child: content),
                )
              : content;
        },
      ),
    );
  }

  void _select(String id) {
    widget.model.select(id);
    _query.clear();
    widget.model.setQuery('');
  }

  Widget _search(BuildContext context) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    return Material(
      color: p.card,
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('history-search'),
                    controller: _query,
                    autofocus: true,
                    onChanged: m.setQuery,
                    onSubmitted: (_) {
                      if (m.suggestions.isNotEmpty) {
                        _select(m.suggestions.first.id);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l.historySearch,
                      prefixIcon: const Icon(Icons.search, size: 18),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.close,
                  onPressed: () => setState(() => _searchOpen = false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          if (m.query.trim().isNotEmpty)
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final row in m.suggestions.take(50))
                    ListTile(
                      key: ValueKey('history-select-${row.id}'),
                      dense: true,
                      title: Text(
                        row.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        row.group,
                        style: TextStyle(fontSize: 11, color: p.muted),
                      ),
                      trailing: m.selected.contains(row.id)
                          ? const Icon(Icons.check, size: 17)
                          : null,
                      onTap: () => _select(row.id),
                    ),
                  if (m.suggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(l.noMatches),
                    ),
                ],
              ),
            ),
          if (m.selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  for (final row in m.data.rows.where(
                    (r) => m.selected.contains(r.id),
                  ))
                    InputChip(
                      label: Text(
                        row.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => m.select(row.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, Size viewport) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    final scale = MediaQuery.textScalerOf(context);
    final nameWidth = viewport.width <= 760
        ? (viewport.width < 360 ? 150.0 : 166.0)
        : 230.0;
    final dates = m.dates, rows = m.rows;
    final lines = <(String, HistoryRow?)>[
      for (final group in m.groups)
        if (rows.any((r) => r.group == group)) ...[
          (group, null),
          for (final row in rows.where((r) => r.group == group)) ('', row),
        ],
    ];
    String unit(HistoryRow row) {
      final units = row.points.map((p) => p.unit).toSet();
      return units.length == 1 && units.single != '—' ? units.single : '';
    }

    TextSpan name(HistoryRow row) => TextSpan(
      children: [
        TextSpan(
          text: row.name,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            letterSpacing: -.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (unit(row).isNotEmpty)
          TextSpan(
            text: '${row.name.length > 22 ? "\n" : " "}${unit(row)}',
            style: TextStyle(fontSize: 11, color: p.secondary),
          ),
      ],
    );
    final heights = [
      for (final line in lines)
        line.$2 == null
            ? math.max(26.0, scale.scale(11) * 1.5 + 8)
            : math.max(
                math.max(
                  28.0,
                  scale.scale(12.5) *
                          1.5 *
                          line.$2!.points.fold<int>(
                            1,
                            (count, point) => math.max(
                              count,
                              m.points(line.$2!, point.date).length,
                            ),
                          ) +
                      8,
                ),
                (() {
                  final painter = TextPainter(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [name(line.$2!)],
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: scale,
                  )..layout(maxWidth: nameWidth - 8);
                  return painter.height + 8;
                })(),
              ),
    ];
    final widths = [
      for (final date in dates)
        rows
                .expand((r) => m.points(r, date))
                .any((v) => v.source.toLowerCase().contains('см-клиника'))
            ? 85.0 * (scale.scale(12) / 12)
            : (viewport.width < 410 ? 66.0 : 68.0) * (scale.scale(12) / 12),
    ];
    final headerHeight = math.max(
      38.0,
      scale.scale(12) * 1.25 + scale.scale(10.5) * 1.25 + 11,
    );
    Widget cell(
      Widget child, {
      required double height,
      double? width,
      Color? color,
      bool center = false,
    }) => Container(
      width: width,
      height: height,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(color: p.line.withValues(alpha: .8)),
          right: BorderSide(color: p.line.withValues(alpha: .45)),
        ),
      ),
      child: child,
    );
    Widget title(int i) {
      final line = lines[i], row = line.$2;
      if (row == null) {
        return cell(
          Text(
            line.$1.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.accent,
            ),
          ),
          height: heights[i],
          color: p.accentSoft,
        );
      }
      return Tooltip(
        message: '${row.name}\n${row.context}',
        child: InkWell(
          key: ValueKey('history-row-${row.id}'),
          onTap: () => widget.onOpenRow?.call(row),
          child: cell(Text.rich(name(row)), height: heights[i], color: p.card),
        ),
      );
    }

    Widget value(int i, int j) {
      final row = lines[i].$2, date = dates[j];
      if (row == null) {
        return cell(
          const SizedBox.shrink(),
          height: heights[i],
          width: widths[j],
          color: p.accentSoft,
        );
      }
      final points = m.points(row, date),
          high = points.any((p) => p.status == 'high'),
          low = points.any((p) => p.status == 'low');
      final content = points
          .map(
            (v) =>
                '${v.value}${v.status == 'high'
                    ? ' ↑'
                    : v.status == 'low'
                    ? ' ↓'
                    : ''}${unit(row).isEmpty && v.unit.isNotEmpty ? ' ${v.unit}' : ''}',
          )
          .join('\n');
      return cell(
        Semantics(
          label: '${row.name} · $date',
          child: Tooltip(
            message: points
                .map((v) => '${v.value} ${v.unit}\n${v.reference}\n${v.source}')
                .join('\n'),
            child: Text(
              content.isEmpty ? '—' : content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: high
                    ? p.red
                    : low
                    ? p.blue
                    : content.isEmpty
                    ? p.muted
                    : p.ink,
                fontWeight: high || low || j == dates.length - 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
        height: heights[i],
        width: widths[j],
        center: true,
        color: high
            ? p.redSoft.withValues(alpha: .55)
            : low
            ? p.blueSoft.withValues(alpha: .55)
            : j == dates.length - 1
            ? p.accentSoft.withValues(alpha: .35)
            : p.card,
      );
    }

    final table = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: nameWidth,
          child: Column(
            children: [
              cell(
                Text(
                  l.indicator,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                height: headerHeight,
                color: p.accentSoft,
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('history-names'),
                  controller: _names,
                  padding: EdgeInsets.zero,
                  itemCount: lines.length,
                  itemBuilder: (_, i) => title(i),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('history-horizontal'),
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(68, widths.fold<double>(0, (a, b) => a + b)),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var j = 0; j < dates.length; j++)
                        cell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd.MM.yy')
                                    .format(historyDate(dates[j])),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                rows
                                    .expand((r) => m.points(r, dates[j]))
                                    .map((p) => p.source)
                                    .toSet()
                                    .join(' · ')
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.25,
                                  color: p.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          height: headerHeight,
                          width: widths[j],
                          center: true,
                          color: p.accentSoft,
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      key: const Key('history-values'),
                      controller: _values,
                      padding: EdgeInsets.zero,
                      itemCount: lines.length,
                      itemBuilder: (_, i) => Row(
                        children: [
                          for (var j = 0; j < dates.length; j++) value(i, j),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return Stack(
      children: [
        Positioned.fill(child: table),
        Positioned.fill(
          top: headerHeight,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _names,
                builder: (context, _) {
                  var position = -(_names.positions.lastOrNull?.pixels ?? 0.0);
                  final headers = <Widget>[];
                  for (var i = 0; i < lines.length; i++) {
                    if (lines[i].$2 == null) {
                      headers.add(
                        Positioned(
                          top: position,
                          left: 0,
                          right: 0,
                          height: heights[i],
                          child: ExcludeSemantics(
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(4),
                              color: p.accentSoft,
                              child: Text(
                                lines[i].$1.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    position += heights[i];
                  }
                  return Stack(children: headers);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventTimeline extends StatefulWidget {
  const _EventTimeline({required this.model});
  final HistoryViewModel model;
  @override
  State<_EventTimeline> createState() => _EventTimelineState();
}

class _EventTimelineState extends State<_EventTimeline> {
  final _scroll = ScrollController();
  bool _positioned = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_moved);
  }

  void _moved() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    final start = model.period.start, end = model.period.end;
    final firstMonth = start.year * 12 + start.month - 1;
    final months = math.max(1, end.year * 12 + end.month - firstMonth);
    final width = math.max(280.0, months * 104.0);
    double offset(CalendarDate date) =>
        ((date.year * 12 + date.month - 1 - firstMonth) +
            (date.day - 1) / DateTime.utc(date.year, date.month + 1, 0).day) *
        104;
    final labels = [
      l.localMedications,
      l.historyIllnesses,
      l.historyComplaints,
      l.localMeasurements,
    ];
    final tracks =
        <
          ({
            HistoryEventKind kind,
            List<({HistoryEvent event, double left, double width, int lane})>
            marks,
            double height,
          })
        >[];
    for (final kind in HistoryEventKind.values) {
      final lanes = <double>[];
      final marks =
          <({HistoryEvent event, double left, double width, int lane})>[];
      final events = model.events.where((e) => e.kind == kind).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      for (final event in events) {
        final left = offset(event.start).clamp(0.0, width - 120).toDouble();
        final span = kind == HistoryEventKind.medication
            ? (offset(event.end ?? end) - left)
                  .clamp(120.0, width - left)
                  .toDouble()
            : 120.0;
        var lane = lanes.indexWhere((last) => last <= left);
        if (lane < 0) {
          lane = lanes.length;
          lanes.add(0);
        }
        lanes[lane] = left + span + 4;
        marks.add((event: event, left: left, width: span, lane: lane));
      }
      tracks.add((
        kind: kind,
        marks: marks,
        height: math.max(36.0, lanes.length * 36.0),
      ));
    }
    if (!_positioned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
          _positioned = true;
        }
      });
    }
    final totalHeight =
        24.0 + tracks.fold<double>(0, (height, t) => height + t.height);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.paper,
        border: Border.symmetric(horizontal: BorderSide(color: p.line)),
      ),
      child: model.events.isEmpty
          ? Center(child: Text(l.historyNoEvents))
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        for (final track in tracks)
                          Container(
                            height: track.height,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: p.line)),
                            ),
                            child: Text(
                              labels[track.kind.index],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('history-timeline'),
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        height: totalHeight,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 24,
                              child: Row(
                                children: [
                                  for (var i = 0; i < months; i++)
                                    SizedBox(
                                      width: 104,
                                      child: Text(
                                        DateFormat.yMMM(l.localeName).format(
                                          DateTime.utc(
                                            start.year,
                                            start.month + i,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: p.secondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            for (final track in tracks)
                              Container(
                                height: track.height,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: p.line),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    for (final mark in track.marks)
                                      Positioned(
                                        left: mark.left,
                                        top: mark.lane * 36,
                                        width: mark.width,
                                        height: 32,
                                        child: Tooltip(
                                          message:
                                              '${mark.event.name}\n${mark.event.start}${mark.event.end == null ? '' : ' — ${mark.event.end}'}\n${mark.event.detail}',
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.only(
                                                left:
                                                    (_scroll.hasClients
                                                            ? _scroll.offset -
                                                                  mark.left
                                                            : 0)
                                                        .clamp(
                                                          0.0,
                                                          mark.width - 100,
                                                        )
                                                        .toDouble() +
                                                    6,
                                                right: 6,
                                              ),
                                              alignment: Alignment.centerLeft,
                                              backgroundColor:
                                                  track.kind ==
                                                      HistoryEventKind
                                                          .medication
                                                  ? p.accentSoft
                                                  : p.card,
                                            ),
                                            onPressed: () => showDialog<void>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(mark.event.name),
                                                content: Text(
                                                  '${mark.event.start}${mark.event.end == null ? '' : ' — ${mark.event.end}'}\n${mark.event.detail}',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text(l.close),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              mark.event.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
