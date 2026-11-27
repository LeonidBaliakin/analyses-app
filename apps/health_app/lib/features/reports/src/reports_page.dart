import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/record_fields.dart';
import 'reports_view_model.dart';
import '../../history/history.dart';
import '../../../presentation/reference_widgets.dart';
import 'local_history.dart';
import '../../records/records.dart';

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
  const ReportsPage({required this.model, this.onClose, super.key});
  final ReportsViewModel model;
  final VoidCallback? onClose;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  HistoryViewModel? _history;
  HealthReport get _all => HealthReport.build(
    widget.model.records.entries,
    RecordsViewModel.profileId,
    ReportPeriod(CalendarDate(1, 1, 1), CalendarDate(9999, 12, 31)),
  );
  @override
  void initState() {
    super.initState();
    widget.model.records.addListener(_update);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = localHistoryData(_all, context);
    if (_history == null) {
      _history = HistoryViewModel(data, today: widget.model.records.today);
    } else {
      _history!.updateData(data);
    }
  }

  void _update() {
    if (mounted) _history?.updateData(localHistoryData(_all, context));
  }

  @override
  void dispose() {
    widget.model.records.removeListener(_update);
    _history?.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final history = _history!,
        m = widget.model,
        l = AppLocalizations.of(context);
    if (history.invalidPeriod) return;
    m.setPeriod(history.period.start.toString(), history.period.end.toString());
    final html = historyDocument(
      history,
      l,
      profile: m.records.profile == null
          ? ''
          : recordFields(
              l,
              m.records.profile!.record,
            ).map((f) => '${f.$1}: ${f.$2}').join(' · '),
    );
    if (await m.saveHtml(html, snapshotPeriod: history.period) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.reportSaved)));
    }
  }

  void _details(HistoryRow row) {
    final l = AppLocalizations.of(context);
    final series = _all.series.firstWhere(
      (s) => s.results.any((r) => r.id == row.id),
    );
    showReferenceSheet(
      context,
      row.name,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final result in series.results.where(
            (r) => _history!.period.includes(r.date),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in recordFields(l, result))
                    if (field.$2.isNotEmpty) Text('${field.$1}: ${field.$2}'),
                  if (result.documentSource != null)
                    Text(
                      '${l.reportOriginal}: ${result.documentSource!.fields['evidence'] ?? ''}',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model, l = AppLocalizations.of(context);
      return Column(
        children: [
          if (m.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.reportExportError),
            ),
          if (!m.canExport)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.reportSaveUnavailable),
            ),
          Expanded(
            child: AnalysisHistoryView(
              model: _history!,
              onClose: widget.onClose,
              onCopy: m.copy == null
                  ? null
                  : () async {
                      if (await m.copyText(
                            historyText(
                              _history!,
                              l,
                              profile: m.records.profile == null
                                  ? ''
                                  : recordFields(l, m.records.profile!.record)
                                        .map((f) => '${f.$1}: ${f.$2}')
                                        .join(' · '),
                            ),
                          ) &&
                          context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l.reportCopied)));
                      }
                    },
              onOpenRow: _details,
              onExport: m.canExport ? _export : null,
              exporting: m.exporting,
            ),
          ),
        ],
      );
    },
  );
}
