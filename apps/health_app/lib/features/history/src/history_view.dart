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
    this.exporting = false,
    super.key,
  });
  final HistoryViewModel model;
  final VoidCallback? onClose, onExport, onCopy;
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

  Widget _content(BuildContext context) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    final labels = [
      l.latestVisit,
      l.historyRecent,
      l.historyAll,
      l.historyCustom,
    ];
    return Material(
      color: p.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 600 || constraints.maxHeight < 450;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    if (widget.onClose != null)
                      BackButton(onPressed: widget.onClose),
                    Expanded(
                      child: Text(
                        l.analysisHistory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 16 : 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('history-events-toggle'),
                      tooltip: l.historyEvents,
                      onPressed: m.toggleEvents,
                      isSelected: m.showEvents,
                      icon: const Icon(Icons.timeline),
                    ),
                    IconButton(
                      key: const Key('history-rotate'),
                      tooltip: l.historyRotate,
                      onPressed: () => setState(() => _rotated = !_rotated),
                      icon: const Icon(Icons.screen_rotation),
                    ),
                    if (widget.onExport != null)
                      IconButton(
                        key: const Key('history-export'),
                        tooltip: l.historyPrint,
                        onPressed: m.invalidPeriod || widget.exporting
                            ? null
                            : widget.onExport,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    if (widget.onExport == null && widget.onCopy != null)
                      IconButton(
                        key: const Key('copy-local-report'),
                        tooltip: l.reportCopy,
                        onPressed: widget.exporting || m.invalidPeriod
                            ? null
                            : widget.onCopy,
                        icon: const Icon(Icons.copy),
                      ),
                  ],
                ),
              ),
              if (m.data.isDemo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l.demoTitle,
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    PopupMenuButton<HistoryPeriod>(
                      key: const Key('history-period'),
                      tooltip: l.historyPeriod,
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
                          PopupMenuItem(
                            value: value,
                            child: Text(labels[value.index]),
                          ),
                      ],
                      child: SizedBox(
                        width: compact ? constraints.maxWidth * .40 : 190,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            labels[m.periodKind.index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${m.period.start} — ${m.period.end}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                    ),
                    IconButton(
                      tooltip: l.historyScrollBack,
                      onPressed: () => _pan(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: l.historyScrollForward,
                      onPressed: () => _pan(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              if (_datesOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
              if (!compact)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    l.historyTableHint,
                    style: TextStyle(color: p.secondary, fontSize: 12),
                  ),
                ),
              if (m.showEvents)
                SizedBox(
                  height: compact ? 126 : 188,
                  child: _EventTimeline(model: m),
                ),
              if (m.selected.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final row in m.data.rows.where(
                        (r) => m.selected.contains(r.id),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text(row.name),
                            selected: true,
                            onSelected: (_) => m.select(row.id),
                            onDeleted: () => m.select(row.id),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          m.reset();
                          _query.clear();
                          _syncDates();
                        },
                        child: Text(l.historyReset),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: m.rows.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(l.historyEmpty),
                              ),
                            )
                          : _table(context),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: math.min(340, constraints.maxWidth - 24),
                          maxHeight: math.max(48, constraints.maxHeight * .52),
                        ),
                        child: _search(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _search(BuildContext context) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    return Material(
      color: p.card,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_searchOpen) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                key: const Key('history-search'),
                controller: _query,
                onChanged: m.setQuery,
                decoration: InputDecoration(
                  labelText: l.historySearch,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final row in m.suggestions.take(50))
                    CheckboxListTile(
                      key: ValueKey('history-select-${row.id}'),
                      title: Text(
                        row.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        [
                          row.group,
                          row.context,
                        ].where((v) => v.isNotEmpty).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: m.selected.contains(row.id),
                      onChanged: (_) => m.select(row.id),
                    ),
                  if (m.suggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(l.noMatches),
                    ),
                ],
              ),
            ),
          ],
          IconButton(
            key: const Key('history-search-toggle'),
            tooltip: _searchOpen ? l.close : l.historySearch,
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: p.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context) {
    final m = widget.model,
        l = AppLocalizations.of(context),
        p = OrangePalette.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final rowHeight = math.max(48.0, 42 * scale);
    final dates = m.dates, rows = m.rows;
    final lines = <(String, HistoryRow?)>[
      for (final group in m.groups)
        if (rows.any((row) => row.group == group)) ...[
          (group, null),
          for (final row in rows.where((row) => row.group == group)) ('', row),
        ],
    ];
    final nameWidth = MediaQuery.sizeOf(context).width < 600 ? 142.0 : 220.0;
    final valueWidth = math.max(112.0, 104 * scale);
    Widget cell(Widget child, {double? width, Color? color}) => Container(
      width: width,
      height: rowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border(
          right: BorderSide(color: p.line),
          bottom: BorderSide(color: p.line),
        ),
      ),
      child: child,
    );
    Widget title((String, HistoryRow?) line) {
      final row = line.$2;
      if (row == null) {
        return cell(
          Text(
            line.$1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.accent,
            ),
          ),
          color: p.accentSoft,
        );
      }
      return Tooltip(
        message: '${row.name}\n${row.context}',
        child: InkWell(
          key: ValueKey('history-row-${row.id}'),
          onTap: () => widget.onOpenRow?.call(row),
          child: cell(
            Text(
              row.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            color: p.paper,
          ),
        ),
      );
    }

    Widget value(HistoryRow? row, CalendarDate date) {
      if (row == null) {
        return cell(
          const SizedBox.shrink(),
          width: valueWidth,
          color: p.accentSoft,
        );
      }
      final points = m.points(row, date);
      final content = points
          .map(
            (point) =>
                '${point.value}${point.status == 'high'
                    ? ' ↑'
                    : point.status == 'low'
                    ? ' ↓'
                    : ''} ${point.unit}',
          )
          .join('\n');
      return cell(
        Semantics(
          label: '${row.name} · $date',
          child: Tooltip(
            message: points
                .map(
                  (point) =>
                      '${point.value} ${point.unit}\n${point.reference}\n${point.source}',
                )
                .join('\n'),
            child: Text(
              content.isEmpty ? '—' : content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        width: valueWidth,
        color: points.any((p) => p.status == 'high')
            ? p.redSoft
            : points.any((p) => p.status == 'low')
            ? p.blueSoft
            : null,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: nameWidth,
          child: Column(
            children: [
              cell(
                Text(
                  l.indicator,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                color: p.paper,
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('history-names'),
                  controller: _names,
                  padding: const EdgeInsets.only(bottom: 76),
                  itemExtent: rowHeight,
                  itemCount: lines.length,
                  itemBuilder: (_, i) => title(lines[i]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const Key('history-horizontal'),
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(valueWidth, valueWidth * dates.length),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final date in dates)
                          cell(
                            Text(
                              DateFormat.yMMMd(l.localeName)
                                  .format(historyDate(date)),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            width: valueWidth,
                            color: p.paper,
                          ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        key: const Key('history-values'),
                        controller: _values,
                        padding: const EdgeInsets.only(bottom: 76),
                        itemExtent: rowHeight,
                        itemCount: lines.length,
                        itemBuilder: (_, i) => Row(
                          children: [
                            for (final date in dates) value(lines[i].$2, date),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
