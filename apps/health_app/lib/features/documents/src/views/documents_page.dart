import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../results/results.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({
    required this.catalog,
    required this.onAdd,
    this.onAddEvent,
    this.onDiary,
    super.key,
  });
  final DemoCatalog catalog;
  final VoidCallback? onAddEvent, onDiary;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return DemoPage(
      children: [
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SectionHeading(l.results),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(l.addAnalysis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecordActions(onAddEvent: onAddEvent, onDiary: onDiary),
              SectionHeading(l.visitHistory),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 14,
                  horizontalMargin: 0,
                  headingRowHeight: 38,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 78,
                  columns: [
                    for (final title in [
                      l.dateLabel,
                      l.labLabel,
                      l.resultCount(0).replaceFirst('0', '').trim(),
                      l.statusLabel,
                      l.fileLabel,
                    ])
                      DataColumn(
                        label: Text(
                          title,
                          style: TextStyle(color: p.muted, fontSize: 11),
                        ),
                      ),
                  ],
                  rows: [
                    for (var i = 0; i < catalog.uploads.length; i++)
                      DataRow(
                        cells: [
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  catalog.uploads[i][0].substring(0, 8),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  catalog.uploads[i][0].substring(8),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFE8590C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              catalog.uploads[i][1],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              catalog.uploads[i][3],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: l.verified,
                              child: Icon(
                                Icons.check_circle_outline,
                                color: p.green,
                                size: 20,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: l.openReport,
                              icon: Icon(
                                Icons.description_outlined,
                                color: p.accent,
                                size: 20,
                              ),
                              onPressed: () => showVisitReport(
                                context,
                                catalog,
                                catalog.dates.length - 1 - i,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
