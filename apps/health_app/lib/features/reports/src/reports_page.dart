import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/record_fields.dart';
import 'reports_view_model.dart';
import 'report_document.dart';

class ReportsSummary extends StatelessWidget {
  const ReportsSummary({required this.model, required this.onOpen, super.key});
  final ReportsViewModel model;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final l = AppLocalizations.of(context), r = model.report;
      return PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.reportSummary,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('${r.period.start} — ${r.period.end}'),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('${l.localResults}: ${r.results.length}'),
                Text('${l.localMedications}: ${r.medications.length}'),
                Text('${l.localMeasurements}: ${r.measurements.length}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.reportNoInterpretation),
            for (final series in r.series.take(8))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${series.latestOnDate.map((v) => '${v.name}: ${v.value.raw} ${v.unit} · ${v.date}').join('\n')}${series.previous == null ? '' : '\n${l.reportPrevious}: ${series.previous!.value.raw} ${series.previous!.unit} · ${series.previous!.date}'}',
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('open-local-report'),
              onPressed: onOpen,
              child: Text(l.reportTitle),
            ),
          ],
        ),
      );
    },
  );
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.model, super.key});
  final ReportsViewModel model;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final start = TextEditingController(
        text: widget.model.period.start.toString(),
      ),
      end = TextEditingController(text: widget.model.period.end.toString());
  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model, l = AppLocalizations.of(context), r = m.report;
      Widget section(String title, Iterable<HealthRecord> records) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          for (final record in records)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in recordFields(l, record))
                      if (f.$2.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${f.$1}: ${f.$2}'),
                        ),
                    if (record is LabResult && record.documentSource != null)
                      Text(
                        '${l.reportOriginal}: ${record.documentSource!.fields['evidence'] ?? ''}',
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
      return UnobstructedPane(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.reportTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.reportScope),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final pair in [
                        (start, l.reportFrom, 'report-from'),
                        (end, l.reportTo, 'report-to'),
                      ])
                        SizedBox(
                          width: 260,
                          child: TextField(
                            key: Key(pair.$3),
                            controller: pair.$1,
                            onChanged: (_) => m.setPeriod(start.text, end.text),
                            decoration: InputDecoration(
                              labelText: pair.$2,
                              hintText: 'YYYY-MM-DD',
                              errorText: m.invalid ? l.reportInvalid : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('export-local-report'),
                    onPressed: !m.canExport || m.invalid || m.exporting
                        ? null
                        : () async {
                            final snapshot = m.report;
                            final html = reportDocument(snapshot, l);
                            if (await m.saveHtml(
                                  html,
                                  snapshotPeriod: snapshot.period,
                                ) &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.reportSaved)),
                              );
                            }
                          },
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l.reportExport),
                  ),
                  if (!m.canExport) Text(l.reportSaveUnavailable),
                  if (m.copy != null)
                    TextButton.icon(
                      key: const Key('copy-local-report'),
                      onPressed: m.invalid || m.exporting
                          ? null
                          : () async {
                              if (await m.copyText(reportText(m.report, l)) &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.reportCopied)),
                                );
                              }
                            },
                      icon: const Icon(Icons.copy),
                      label: Text(l.reportCopy),
                    ),
                  if (m.error != null)
                    Text(
                      m.error == 'copy'
                          ? l.reportCopyError
                          : l.reportExportError,
                    ),
                  const SizedBox(height: 12),
                  Text(l.reportNoInterpretation),
                  if (r.profile != null) section(l.profile, [r.profile!]),
                  section(l.localResults, r.results),
                  section(l.localMedications, r.medications),
                  section(l.localMeasurements, r.measurements),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
