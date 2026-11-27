import 'local_capture.dart';
import 'local_overview.dart';

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/category_presentation.dart';
import '../../../presentation/reference_widgets.dart';
import 'record_editor.dart';
import 'record_history.dart';
import 'records_view_model.dart';
import '../../reports/reports.dart';
import '../../sync/sync.dart';

enum RecordsSection { summary, results, profile }

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    required this.model,
    required this.section,
    this.onOpenOriginals,
    this.reports,
    this.sync,
    this.onOpenReport,
    this.onOpenSync,
    super.key,
  });
  final RecordsViewModel model;
  final RecordsSection section;
  final VoidCallback? onOpenOriginals;
  final ReportsViewModel? reports;
  final SyncViewModel? sync;
  final VoidCallback? onOpenReport, onOpenSync;
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> with WidgetsBindingObserver {
  String _query = '';
  AnalysisCategory? _category;
  late CalendarDate _onDate = widget.model.today;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.model.load();
  }

  void _add(RecordKind kind) => showRecordEditor(context, widget.model, kind);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final model = widget.model;
        final profile = model.profile;
        return SingleChildScrollView(
          key: PageStorageKey(widget.section),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profile != null &&
                      widget.section == RecordsSection.summary)
                    LocalOverview(
                      model: model,
                      onAddEvent: () => showLocalEventCapture(context, model),
                      onHistory: widget.onOpenReport,
                    ),
                  if (profile != null &&
                      widget.section == RecordsSection.results)
                    _heading(
                      l.myAnalyses,
                      l.addAnalysis,
                      () => _add(RecordKind.result),
                    ),
                  if (profile != null &&
                      widget.section == RecordsSection.results &&
                      MediaQuery.sizeOf(context).width <
                          AppLayout.railBreakpoint)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 8),
                      child: Text(
                        recordName(profile.record),
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                    ),
                  if (profile == null)
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  switch (widget.section) {
                                    RecordsSection.summary => l.summary,
                                    RecordsSection.results => l.results,
                                    RecordsSection.profile => l.profile,
                                  },
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ),
                              IconButton(
                                tooltip: l.localRefresh,
                                onPressed: model.loading || model.saving
                                    ? null
                                    : model.load,
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.sync == null)
                            Text(l.localOnly)
                          else
                            ListenableBuilder(
                              listenable: widget.sync!,
                              builder: (context, _) =>
                                  Text(l.syncPending(widget.sync!.pending)),
                            ),
                          if (widget.onOpenSync != null)
                            TextButton.icon(
                              onPressed: widget.onOpenSync,
                              icon: const Icon(Icons.sync),
                              label: Text(l.syncTitle),
                            ),
                          if (widget.onOpenOriginals != null)
                            TextButton.icon(
                              onPressed: widget.onOpenOriginals,
                              icon: const Icon(Icons.folder_open_outlined),
                              label: Text(l.originalsTitle),
                            ),
                          if (profile != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              recordName(profile.record),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (model.loading) const LinearProgressIndicator(),
                  if (model.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          recordsErrorText(l, model.error!),
                          style: TextStyle(color: p.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (model.loaded && profile == null)
                    PaperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.localEmpty,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(l.localStart),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('create-profile'),
                            onPressed: () => _add(RecordKind.profile),
                            child: Text(l.localCreateProfile),
                          ),
                        ],
                      ),
                    ),
                  if (profile != null) ...[
                    if (widget.section != RecordsSection.summary)
                      RecordActions(
                        onAddEvent: () => showLocalEventCapture(context, model),
                        onDiary: () =>
                            showLocalEventCapture(context, model, diary: true),
                      ),
                    if (widget.section == RecordsSection.profile) ...[
                      PaperCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (label, value) in recordFields(
                              l,
                              profile.record,
                              terminology: model.terminology,
                            ))
                              if (value.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text('$label: $value'),
                                ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => showRecordEditor(
                                    context,
                                    model,
                                    RecordKind.profile,
                                    entry: profile,
                                  ),
                                  child: Text(l.localEditProfile),
                                ),
                                TextButton(
                                  onPressed: () => showRecordHistory(
                                    context,
                                    model,
                                    profile.record.id,
                                  ),
                                  child: Text(l.localHistory),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.section != RecordsSection.profile) ...[
                      _heading(
                        l.localResults,
                        l.localAddResult,
                        () => _add(RecordKind.result),
                      ),
                      const SizedBox(height: 12),
                      if (widget.section == RecordsSection.summary) ...[
                        AdaptiveTiles(
                          children: [
                            for (final category in AnalysisCategory.values)
                              _categoryTile(category),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (widget.section == RecordsSection.results ||
                          _category != null) ...[
                        TextField(
                          key: const Key('local-result-search'),
                          onChanged: (q) => setState(() => _query = q),
                          decoration: InputDecoration(
                            labelText: l.localSearch,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        if (_category != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              label: Text(
                                categoryPresentation(context, _category!).title,
                              ),
                              onDeleted: () => setState(() => _category = null),
                            ),
                          ),
                        const SizedBox(height: 12),
                        ..._results(),
                        const SizedBox(height: 20),
                      ],
                    ],
                    if (widget.section == RecordsSection.profile) ...[
                      _heading(
                        l.localMedications,
                        l.localAddMedication,
                        () => _add(RecordKind.medication),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('medication-date'),
                        initialValue: _onDate.toString(),
                        decoration: InputDecoration(
                          labelText: '${l.localOnDate} (${l.localDateHint})',
                          errorMaxLines: 3,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          try {
                            CalendarDate.parse(value ?? '');
                            return null;
                          } catch (_) {
                            return l.localDateInvalid;
                          }
                        },
                        onChanged: (value) {
                          try {
                            final date = CalendarDate.parse(value);
                            setState(() => _onDate = date);
                          } catch (_) {
                            /* Keep the last valid selected date. */
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ..._entries(RecordKind.medication),
                      const SizedBox(height: 24),
                      _heading(
                        l.localMeasurements,
                        l.localAddMeasurement,
                        () => _add(RecordKind.measurement),
                      ),
                      const SizedBox(height: 12),
                      ..._entries(RecordKind.measurement),
                    ],
                    QuietFold(
                      title: Text(l.localOnly),
                      children: [
                        if (widget.sync != null)
                          ListenableBuilder(
                            listenable: widget.sync!,
                            builder: (context, _) =>
                                Text(l.syncPending(widget.sync!.pending)),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: model.load,
                              icon: const Icon(Icons.refresh),
                              label: Text(l.localRefresh),
                            ),
                            if (widget.onOpenSync != null)
                              TextButton.icon(
                                onPressed: widget.onOpenSync,
                                icon: const Icon(Icons.sync),
                                label: Text(l.syncTitle),
                              ),
                            if (widget.onOpenOriginals != null)
                              TextButton.icon(
                                onPressed: widget.onOpenOriginals,
                                icon: const Icon(Icons.folder_open_outlined),
                                label: Text(l.originalsTitle),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heading(String title, String action, VoidCallback onTap) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      FilledButton.tonal(onPressed: onTap, child: Text(action)),
    ],
  );

  Widget _categoryTile(AnalysisCategory category) {
    final style = categoryPresentation(context, category);
    final count = widget.model
        .ofKind(RecordKind.result)
        .where((e) => (e.record as LabResult).category == category)
        .length;
    final l = AppLocalizations.of(context);
    return ColorTile(
      title: style.title,
      subtitle: l.resultCount(count),
      icon: Icon(style.icon, color: Colors.white),
      color: style.color,
      empty: count == 0,
      footer: Text(l.localManual),
      onTap: () => setState(() => _category = category),
    );
  }

  List<Widget> _results() {
    final entries =
        widget.model.ofKind(RecordKind.result).where((e) {
          final r = e.record as LabResult;
          return (_category == null || r.category == _category) &&
              '${r.name} ${r.value.raw} ${r.laboratory}'.toLowerCase().contains(
                _query.toLowerCase(),
              );
        }).toList()..sort(
          (a, b) => (b.record as LabResult).date.compareTo(
            (a.record as LabResult).date,
          ),
        );
    if (entries.isEmpty) return [Text(AppLocalizations.of(context).localEmpty)];
    final visits = <(CalendarDate, String), List<RecordEntry>>{};
    for (final entry in entries) {
      final result = entry.record as LabResult;
      visits.putIfAbsent((result.date, result.laboratory), () => []).add(entry);
    }
    return [
      for (final visit in visits.entries)
        ExpansionTile(
          key: PageStorageKey('local-visit-${visit.key.$1}-${visit.key.$2}'),
          initiallyExpanded: true,
          title: Text('${visit.key.$1} · ${visit.key.$2}'),
          subtitle: Text(
            AppLocalizations.of(context).resultCount(visit.value.length),
          ),
          children: [for (final entry in visit.value) _entry(entry)],
        ),
    ];
  }

  List<Widget> _entries(RecordKind kind) {
    final entries = widget.model.ofKind(kind);
    entries.sort((a, b) {
      CalendarDate date(HealthRecord r) =>
          r is MedicationCourse ? r.start : (r as HomeMeasurement).date;
      return date(b.record).compareTo(date(a.record));
    });
    return entries.isEmpty
        ? [Text(AppLocalizations.of(context).localEmpty)]
        : [for (final e in entries) _entry(e)];
  }

  Widget _entry(RecordEntry entry) {
    final r = entry.record, l = AppLocalizations.of(context);
    final subtitle = switch (r) {
      MedicalProfile() => '',
      LabResult() => '${r.date} · ${r.value.raw} ${r.unit}\n${r.laboratory}',
      MedicationCourse() =>
        '${r.start} — ${r.end ?? '…'} · ${r.dosage}\n${r.schedule}'
            '${r.activeOn(_onDate) ? '\n${l.localActive} · $_onDate' : ''}',
      HomeMeasurement() => '${r.date} · ${r.value.raw} ${r.unit}\n${r.source}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PaperCard(
        padding: EdgeInsets.zero,
        stripe: r is LabResult
            ? categoryPresentation(context, r.category).color
            : null,
        child: ListTile(
          key: Key('local-record-${r.id}'),
          contentPadding: const EdgeInsets.all(16),
          isThreeLine: false,
          leading: r is LabResult
              ? Icon(
                  categoryPresentation(context, r.category).icon,
                  color: categoryPresentation(context, r.category).color,
                )
              : null,
          title: Text(recordName(r)),
          subtitle: Text(subtitle.trim()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _details(entry),
        ),
      ),
    );
  }

  Future<void> _details(RecordEntry entry) async {
    final l = AppLocalizations.of(context), record = entry.record;
    final edit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recordName(record)),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record is LabResult)
                  Text(categoryPresentation(context, record.category).title),
                for (final (label, value) in recordFields(
                  l,
                  record,
                  terminology: widget.model.terminology,
                ))
                  if (value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('$label: $value'),
                    ),
                Text(
                  record is LabResult && record.documentSource != null
                      ? l.processingImported
                      : l.localManual,
                ),
                if (record is LabResult) ...[
                  const SizedBox(height: 12),
                  Text(l.localNoInterpretation),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                showRecordHistory(context, widget.model, record.id),
            child: Text(l.localHistory),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.localClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.localEdit),
          ),
        ],
      ),
    );
    if (edit == true && mounted) {
      await showRecordEditor(context, widget.model, record.kind, entry: entry);
    }
  }
}
