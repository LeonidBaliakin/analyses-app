import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../results/results.dart';
import '../view_models/visit_list_view_model.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({
    required this.catalog,
    required this.onAdd,
    this.onAddEvent,
    this.onDiary,
    super.key,
  });
  final DemoCatalog catalog;
  final VoidCallback onAdd;
  final VoidCallback? onAddEvent, onDiary;
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final model = VisitListViewModel(widget.catalog.uploads);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final reasons = [
      l.reasonDoctor,
      l.reasonCheckup,
      l.reasonRoutine,
      l.reasonHospital,
      l.reasonSanatorium,
    ];
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => DemoPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.myAnalyses,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: SpotlightAnchor(
                  id: 'add-analysis',
                  child: FilledButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l.addAnalysis),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RecordActions(onAddEvent: widget.onAddEvent, onDiary: widget.onDiary),
          PaperCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 1),
                SectionHeading(l.visitHistory),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.visitReason,
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                    for (final index in [-1, 0, 1, 2, 3, 4])
                      OptionChip(
                        label: Text(
                          index < 0
                              ? l.allOption
                              : '${reasons[index]} ${model.reasons.where((r) => r == index).length}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        selected: model.filter == index,
                        onSelected: (_) => model.selectFilter(index),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = MediaQuery.sizeOf(context).width > 760;
                    Widget text(String v, {Color? color, bool bold = false}) =>
                        Text(
                          v,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: color ?? p.ink,
                            fontWeight: bold
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        );
                    Widget pad(Widget child) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      child: child,
                    );
                    return Table(
                      columnWidths: {
                        0: const FlexColumnWidth(1.2),
                        1: const FlexColumnWidth(1.2),
                        if (wide) 2: const FlexColumnWidth(1.1),
                        wide ? 3 : 2: const FlexColumnWidth(.6),
                        wide ? 4 : 3: const FlexColumnWidth(.7),
                        wide ? 5 : 4: const FixedColumnWidth(28),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder(
                        horizontalInside: BorderSide(color: p.line),
                      ),
                      children: [
                        TableRow(
                          children: [
                            for (final title in [
                              l.dateLabel,
                              l.labShort,
                              if (wide) l.fileLabel,
                              l.resultCount(0).replaceFirst('0', '').trim(),
                              l.statusLabel,
                              '',
                            ])
                              pad(text(title, color: p.muted)),
                          ],
                        ),
                        for (final i in model.visible)
                          TableRow(
                            children: [
                              pad(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    text(
                                      widget.catalog.uploads[i][0].substring(
                                        0,
                                        8,
                                      ),
                                      bold: false,
                                    ),
                                    InkWell(
                                      key: Key('visit-reason-$i'),
                                      onTap: () => _reason(context, i, reasons),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: p.orangeSoft,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          model.reasons[i] < 0
                                              ? l.reasonAdd
                                              : model.reasons[i] == 0
                                              ? l.reasonDoctorShort
                                              : reasons[model.reasons[i]],
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFE8590C),
                                            backgroundColor: p.orangeSoft,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pad(
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: StatusPill(
                                    label: widget.catalog.uploads[i][1],
                                    color: p.accent,
                                    background: p.accentSoft,
                                  ),
                                ),
                              ),
                              if (wide) pad(text(widget.catalog.uploads[i][2])),
                              pad(text(widget.catalog.uploads[i][3])),
                              pad(
                                Icon(
                                  Icons.check_circle,
                                  size: 15,
                                  color: p.green,
                                ),
                              ),
                              IconButton(
                                tooltip: l.openReport,
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(28, 40),
                                ),
                                icon: Icon(
                                  Icons.description_outlined,
                                  size: 17,
                                  color: p.accent,
                                ),
                                onPressed: () => showVisitReport(
                                  context,
                                  widget.catalog,
                                  widget.catalog.dates.length - 1 - i,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reason(BuildContext context, int index, List<String> reasons) {
    final l = AppLocalizations.of(context);
    showReferenceSheet(
      context,
      l.visitReason,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < reasons.length; i++)
            OutlinedButton(
              onPressed: () {
                model.setReason(index, i);
                Navigator.of(context).pop();
              },
              child: Text(reasons[i]),
            ),
          TextButton(
            onPressed: () {
              model.setReason(index, -1);
              Navigator.of(context).pop();
            },
            child: Text(l.clearSelection),
          ),
        ],
      ),
    );
  }
}

void showVisitReport(BuildContext context, DemoCatalog catalog, int visit) {
  final l = AppLocalizations.of(context);
  showReferenceSheet(
    context,
    '${catalog.dates[visit]} · ${catalog.labs[visit]}',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.demoTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final result in catalog.results.where(
          (r) => r.points.any((p) => p.visit == visit),
        ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(result.name, style: const TextStyle(fontSize: 12)),
            trailing: Text(
              '${result.points.firstWhere((p) => p.visit == visit).raw} ${result.unit}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            onTap: () => showResultDetails(context, catalog, result),
          ),
      ],
    ),
  );
}
