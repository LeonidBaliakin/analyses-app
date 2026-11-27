import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_labels.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../history/history.dart';
import '../demo_history.dart';

Color _statusColor(BuildContext context, String status) {
  final p = OrangePalette.of(context);
  return status == 'high'
      ? p.red
      : status == 'low'
      ? p.blue
      : p.green;
}

String _statusLabel(BuildContext context, String status) {
  final l = AppLocalizations.of(context);
  return status == 'high'
      ? l.aboveRange
      : status == 'low'
      ? l.belowRange
      : l.inRange;
}

Future<void> showSystemResults(
  BuildContext context,
  DemoCatalog catalog,
  DemoSystem system,
) => showReferenceSheet(
  context,
  systemTitle(context, system.id),
  system.results.isEmpty
      ? Text(AppLocalizations.of(context).noSystemData)
      : _ResultList(catalog: catalog, results: system.results),
  orange: true,
);

Future<void> showResultFilter(
  BuildContext context,
  DemoCatalog catalog,
  int filter,
) {
  final l = AppLocalizations.of(context);
  final rows = catalog.results
      .where(
        (r) => filter == 2
            ? catalog.olderIds.contains(r.id)
            : catalog.latestIds.contains(r.id) &&
                  (filter == 0
                      ? r.status == 'ok'
                      : filter == 1
                      ? r.status != 'ok'
                      : true),
      )
      .toList();
  return showReferenceSheet(
    context,
    [l.inRange, l.outOfRange, l.notRecently, l.allResults][filter],
    _ResultList(catalog: catalog, results: rows),
  );
}

Future<void> showComparison(BuildContext context, DemoCatalog catalog) {
  final l = AppLocalizations.of(context);
  return showReferenceSheet(
    context,
    l.visitCompare(catalog.dates[catalog.dates.length - 2]),
    _ResultList(
      catalog: catalog,
      results: catalog.results
          .where((r) => catalog.latestIds.contains(r.id))
          .toList(),
      compare: true,
    ),
    fullscreen: true,
  );
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.catalog,
    required this.results,
    this.compare = false,
  });
  final DemoCatalog catalog;
  final List<DemoResult> results;
  final bool compare;
  @override
  Widget build(BuildContext context) {
    final p = OrangePalette.of(context);
    return Column(
      children: [
        for (final result in results)
          InkWell(
            onTap: () => showResultDetails(context, catalog, result),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                          result.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          systemTitle(context, result.systemId),
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (compare && result.previous != null)
                          Text(
                            result.previous!.raw,
                            style: TextStyle(fontSize: 11, color: p.muted),
                          ),
                        Text(
                          '${result.current?.raw ?? '—'} ${result.unit}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: _statusColor(context, result.status),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _statusLabel(context, result.status),
                          style: TextStyle(
                            fontSize: 10,
                            color: _statusColor(context, result.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 17, color: p.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showResultDetails(
  BuildContext context,
  DemoCatalog catalog,
  DemoResult result,
) {
  final l = AppLocalizations.of(context), p = OrangePalette.of(context);
  return showReferenceSheet(
    context,
    result.name,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          systemTitle(context, result.systemId),
          style: TextStyle(fontSize: 12, color: p.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${result.current?.raw ?? '—'} ${result.unit}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _statusColor(context, result.status),
              ),
            ),
            StatusPill(
              label: _statusLabel(context, result.status),
              color: _statusColor(context, result.status),
              background: result.status == 'ok'
                  ? p.greenSoft
                  : result.status == 'high'
                  ? p.redSoft
                  : p.blueSoft,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${l.labReference}: ${result.reference}',
          style: TextStyle(color: p.secondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (result.points.isNotEmpty)
          Container(
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HistoryPainter(result.points, p),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      result.points.first.date,
                      style: TextStyle(fontSize: 10, color: p.muted),
                    ),
                    Text(
                      result.points.last.date,
                      style: TextStyle(fontSize: 10, color: p.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SectionHeading(l.resultHistory),
        const SizedBox(height: 8),
        for (final point in result.points.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(point.date, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: Text(
                    catalog.labs[point.visit],
                    style: TextStyle(fontSize: 11, color: p.muted),
                  ),
                ),
                Text(
                  '${point.raw} ${result.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: _statusColor(context, point.status),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(
          l.sourceDisclaimer,
          style: TextStyle(fontSize: 11, color: p.muted),
        ),
      ],
    ),
    orange: true,
  );
}

class _HistoryPainter extends CustomPainter {
  const _HistoryPainter(this.points, this.palette);
  final List<DemoPoint> points;
  final OrangePalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.value),
        min = values.reduce(math.min),
        max = values.reduce(math.max);
    final spread = max - min, pad = spread == 0 ? 1 : spread * .25;
    Offset position(int i) => Offset(
      12 +
          (size.width - 24) *
              (points.length == 1 ? 0.5 : i / (points.length - 1)),
      size.height -
          14 -
          (size.height - 28) *
              (points[i].value - min + pad) /
              (spread + 2 * pad),
    );
    final grid = Paint()
      ..color = palette.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 14 + (size.height - 28) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(position(0).dx, position(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(position(i).dx, position(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < points.length; i++) {
      final c = points[i].status == 'high'
          ? palette.red
          : points[i].status == 'low'
          ? palette.blue
          : palette.green;
      canvas.drawCircle(position(i), 5, Paint()..color = palette.card);
      canvas.drawCircle(position(i), 3.5, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.palette != palette;
}

Future<void> showHistory(
  BuildContext context,
  DemoCatalog catalog, {
  Future<bool> Function(String, String)? export,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: DemoHistoryPage(
          catalog: catalog,
          export: export,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  ),
);

class DemoHistoryPage extends StatefulWidget {
  const DemoHistoryPage({
    required this.catalog,
    this.export,
    this.exportPdf,
    this.selectedSystemIds,
    this.onClose,
    super.key,
  });
  final DemoCatalog catalog;
  final Set<int>? selectedSystemIds;
  final HistoryPdfExporter? exportPdf;
  final Future<bool> Function(String, String)? export;
  final VoidCallback? onClose;
  @override
  State<DemoHistoryPage> createState() => _DemoHistoryPageState();
}

class _DemoHistoryPageState extends State<DemoHistoryPage> {
  HistoryViewModel? _model;
  bool _exporting = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    if (_model == null) {
      _model = HistoryViewModel(
        demoHistoryData(context, widget.catalog),
        today: CalendarDate(now.year, now.month, now.day),
      );
      if (widget.selectedSystemIds case final ids?) {
        for (final result in widget.catalog.results.where(
          (r) => ids.contains(r.systemId),
        )) {
          _model!.select(result.id);
        }
      }
    } else {
      _model!.updateData(demoHistoryData(context, widget.catalog));
    }
  }

  @override
  void dispose() {
    _model?.dispose();
    super.dispose();
  }

  Future<void> _export({bool share = false}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final l = AppLocalizations.of(context);
    try {
      final snapshot = _model!.printSnapshot();
      final saved = widget.exportPdf != null
          ? await widget.exportPdf!(snapshot, l.localeName, share)
          : await widget.export!(
              'analysis-history.html',
              historyDocument(_model!, l),
            );
      if (saved && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.historyExportHint)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.reportExportError)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnalysisHistoryView(
    model: _model!,
    onClose: widget.onClose,
    onOpenRow: (row) => showResultDetails(
      context,
      widget.catalog,
      widget.catalog.result(row.id),
    ),
    onExport: widget.export == null && widget.exportPdf == null
        ? null
        : _export,
    onShare: widget.exportPdf == null ? null : () => _export(share: true),
    exporting: _exporting,
  );
}

Future<void> showDemoActivity(
  BuildContext context,
  DemoCatalog catalog, {
  bool diary = false,
}) {
  final l = AppLocalizations.of(context);
  final events =
      demoHistoryData(context, catalog).events
          .where((e) => !diary || e.kind == HistoryEventKind.measurement)
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));
  return showReferenceSheet(
    context,
    diary ? l.measurementDiary : l.visitEvents,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.demoTitle),
        for (var i = 0; i < events.length; i++) ...[
          if (i == 0 ||
              events[i - 1].start.month != events[i].start.month ||
              events[i - 1].start.year != events[i].start.year)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                '${events[i].start.year}-${events[i].start.month.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(events[i].name),
            subtitle: Text('${events[i].start} · ${events[i].detail}'),
          ),
        ],
        if (events.isEmpty) Text(l.historyNoEvents),
      ],
    ),
    fullscreen: true,
  );
}
