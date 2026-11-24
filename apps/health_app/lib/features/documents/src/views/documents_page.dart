import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/demo_catalog.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../results/results.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({required this.catalog, required this.onAdd, super.key});
  final DemoCatalog catalog;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return DemoPage(
      children: [
        const RecordActions(),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(l.uploadTitle),
              const SizedBox(height: 5),
              Text(l.uploadIntro, style: TextStyle(color: p.secondary)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.paper,
                  border: Border.all(color: p.line, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(l.uploadDrop, style: TextStyle(color: p.secondary)),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 0,
                      children: [
                        FilledButton(
                          onPressed: onAdd,
                          child: Text(l.takePhoto),
                        ),
                        OutlinedButton(
                          onPressed: onAdd,
                          child: Text(l.fromGallery),
                        ),
                        OutlinedButton(
                          onPressed: onAdd,
                          child: Text(l.filePdf),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l.uploadPermission,
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final pair in [
                (l.photoScreenshot, l.photoAdvice),
                (l.filePdf, l.pdfAdvice),
                (
                  l.forwardMail,
                  '${l.mailAdvice} a.ivanov@in.orange-health.ru · ${l.demoEmail}',
                ),
              ])
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        pair.$2,
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
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
