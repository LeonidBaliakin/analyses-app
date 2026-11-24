import 'package:design_system/design_system.dart';
import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/category_presentation.dart';
import 'processing_view_model.dart';

Future<void> showProcessing(
  BuildContext context,
  ProcessingViewModel model,
  OriginalDocument original,
) async {
  if (!await model.open(original) || !context.mounted) return;
  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => ProcessingPage(model: model)));
}

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({required this.model, super.key});
  final ProcessingViewModel model;
  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  bool _dirty = false;
  Future<void> _close() async {
    if (_dirty) {
      final l = AppLocalizations.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.localDiscard),
          content: Text(l.localDiscardText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.localKeepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.localClose),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), m = widget.model;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.processingTitle),
          leading: IconButton(
            onPressed: _close,
            tooltip: l.localBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: UnobstructedPane(
          child: ListenableBuilder(
            listenable: m,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(m.original?.fileName ?? ''),
                      const SizedBox(height: 12),
                      Text(l.processingConsent),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            key: const Key('process-local'),
                            onPressed: m.running || m.saving || _dirty
                                ? null
                                : () => m.start(ProcessingMode.local),
                            child: Text(l.processingLocal),
                          ),
                          OutlinedButton(
                            key: const Key('process-server'),
                            onPressed: m.running || m.saving || _dirty
                                ? null
                                : () => m.start(ProcessingMode.ownServer),
                            child: Text(l.processingServer),
                          ),
                          if (m.running)
                            TextButton(
                              onPressed: m.cancel,
                              child: Text(l.processingCancel),
                            ),
                        ],
                      ),
                      if (m.running) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        Text(l.processingBackground),
                      ],
                      if (m.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              switch (m.error) {
                                'date' => l.processingDateRequired,
                                'unavailable' => l.processingUnavailable,
                                'upload_first' => l.processingUploadFirst,
                                'already_confirmed' =>
                                  l.processingAlreadyConfirmed,
                                'conflict' => l.processingConflict,
                                'runtime_changed' => l.processingRuntimeChanged,
                                'empty' => l.processingEmpty,
                                'cancelled' => l.processingCancelled,
                                _ => l.processingFailed,
                              },
                              style: TextStyle(
                                color: OrangePalette.of(context).red,
                              ),
                            ),
                          ),
                        ),
                      if (m.jobs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l.processingRuns,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final job in m.jobs)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${job.mode == ProcessingMode.local ? l.processingLocal : l.processingServer} · ${switch (job.status) {
                                ProcessingStatus.queued => l.processingQueued,
                                ProcessingStatus.ocr => l.processingOcr,
                                ProcessingStatus.extracting => l.processingLlm,
                                ProcessingStatus.ready => l.processingReview,
                                ProcessingStatus.failed => l.processingFailed,
                                ProcessingStatus.cancelled => l.processingCancelled,
                                ProcessingStatus.confirmed => l.processingConfirmed,
                              }}',
                            ),
                            onTap: m.running || m.saving || _dirty
                                ? null
                                : () => m.selectJob(job),
                            trailing:
                                !m.running &&
                                    !_dirty &&
                                    [
                                      ProcessingStatus.queued,
                                      ProcessingStatus.ocr,
                                      ProcessingStatus.extracting,
                                      ProcessingStatus.failed,
                                    ].contains(job.status)
                                ? TextButton(
                                    onPressed: () => m.resume(job),
                                    child: Text(l.retry),
                                  )
                                : null,
                          ),
                      ],
                      if (m.draft == null)
                        for (final job in m.jobs.where(
                          (j) =>
                              j.artifact != null &&
                              j.status == ProcessingStatus.failed,
                        ))
                          ExpansionTile(
                            title: Text(l.processingOcrText),
                            children: [
                              for (final page in job.artifact!['pages'] as List)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SelectableText(page['text'] as String),
                                ),
                              TextButton(
                                onPressed: m.running
                                    ? null
                                    : () => m.manualFromOcr(job),
                                child: Text(l.processingManual),
                              ),
                            ],
                          ),
                      if (m.draft case final d?) ...[
                        const SizedBox(height: 16),
                        Text(
                          d.confirmed
                              ? l.processingConfirmed
                              : l.processingReview,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(l.processingReviewHint),
                        ExpansionTile(
                          title: Text(l.processingOcrText),
                          children: [
                            for (final page in d.pages)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(
                                  '${page['number']}\n${page['text']}',
                                ),
                              ),
                          ],
                        ),
                        DraftReviewForm(
                          key: ValueKey('${d.jobId}:${d.revision}'),
                          model: m,
                          draft: d,
                          onDirty: (value) {
                            if (mounted) setState(() => _dirty = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DraftReviewForm extends StatefulWidget {
  const DraftReviewForm({
    required this.model,
    required this.draft,
    required this.onDirty,
    super.key,
  });
  final ProcessingViewModel model;
  final ProcessingDraft draft;
  final ValueChanged<bool> onDirty;
  @override
  State<DraftReviewForm> createState() => _DraftReviewFormState();
}

class _DraftReviewFormState extends State<DraftReviewForm> {
  final _fields = <String, TextEditingController>{};
  final _category = <String, AnalysisCategory>{};
  final _included = <String, bool>{};
  final _kind = <String, ResultValueKind>{};
  final _indicator = <String, String>{}, _unit = <String, String>{};
  @override
  void initState() {
    super.initState();
    for (final r in widget.draft.rows) {
      for (final f in draftFields) {
        _fields['${r.id}:$f'] = TextEditingController(text: r.review[f] ?? '');
      }
      _category[r.id] = r.category;
      _included[r.id] = r.included;
      _kind[r.id] = r.valueKind;
      _indicator[r.id] = r.coding?.indicatorId ?? '';
      _unit[r.id] = r.coding?.unitId ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _text(DraftRow row, String key) => _fields['${row.id}:$key']!.text;
  void _changed() {
    widget.onDirty(true);
    setState(() {});
  }

  ProcessingDraft _edited() {
    final release =
        widget.model.terminology.releases[widget.draft.terminologyReleaseId]!;
    return widget.draft.edited([
      for (final row in widget.draft.rows)
        row.edit(
          {for (final f in draftFields) f: _text(row, f)},
          included: _included[row.id],
          category: _category[row.id],
          valueKind: _kind[row.id],
          coding: _indicator[row.id]!.isEmpty
              ? null
              : release.confirm(
                  indicatorId: _indicator[row.id]!,
                  unitId: _unit[row.id]!.isEmpty ? null : _unit[row.id],
                  sourceName: _text(row, 'name'),
                  sourceUnit: _text(row, 'unit'),
                  sourceLaboratory: _text(row, 'laboratory'),
                  sourceSpecimen: _text(row, 'specimen'),
                  sourceMethod: _text(row, 'method'),
                ),
        ),
    ]);
  }

  Future<void> _addRow() async {
    try {
      final d = _edited();
      final ok = await widget.model.save(
        d.edited([
          ...d.rows,
          DraftRow(
            id: 'manual-${widget.model.newId()}',
            source: {},
            review: {for (final f in draftFields) f: ''},
            valueKind: ResultValueKind.missing,
          ),
        ]),
      );
      if (ok) widget.onDirty(false);
    } on InvalidRecord {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).localValueInvalid),
          ),
        );
      }
    }
  }

  Future<void> _save(bool confirm) async {
    try {
      final d = _edited();
      final ok = confirm
          ? await widget.model.confirm(d)
          : await widget.model.save(d);
      if (ok) widget.onDirty(false);
    } on InvalidRecord {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).localValueInvalid),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        d = widget.draft,
        release = widget.model.terminology.releases[d.terminologyReleaseId];
    final language = Localizations.localeOf(context).languageCode;
    final disabled = d.confirmed || widget.model.saving || widget.model.running;
    String label(String key) => switch (key) {
      'name' => l.localOriginalName,
      'value' => l.localValue,
      'unit' => l.localUnit,
      'reference' => l.localReference,
      'date' => l.dateLabel,
      'laboratory' => l.labLabel,
      'specimen' => l.localSpecimen,
      _ => l.localMethod,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.rows.isEmpty) Text(l.processingEmpty),
        for (final row in [
          for (final r in d.rows)
            release == null
                ? r
                : normalizeRow(
                    r.edit({for (final f in draftFields) f: _text(r, f)}),
                    release,
                  ),
        ])
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _text(row, 'name').isEmpty
                          ? l.processingUnknown
                          : _text(row, 'name'),
                    ),
                    value: _included[row.id],
                    onChanged: disabled
                        ? null
                        : (v) {
                            _included[row.id] = v!;
                            _changed();
                          },
                  ),
                  if (row.source['evidence'] case final evidence?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SelectableText(evidence.raw),
                    ),
                  for (final f in draftFields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        key: Key('draft-${row.id}-$f'),
                        controller: _fields['${row.id}:$f'],
                        enabled: !disabled,
                        onChanged: (_) {
                          if ([
                            'name',
                            'unit',
                            'laboratory',
                            'specimen',
                            'method',
                          ].contains(f)) {
                            _indicator[row.id] = '';
                            _unit[row.id] = '';
                          }
                          _changed();
                        },
                        decoration: InputDecoration(
                          labelText: label(f),
                          helperMaxLines: 4,
                          helperText: row.source[f]?.issue != null
                              ? l.processingUnbacked
                              : row.source[f]?.raw.isNotEmpty == true
                              ? l.processingSourceValue(row.source[f]!.raw)
                              : l.processingUnknown,
                          errorText:
                              f == 'date' &&
                                  widget.model.error == 'date' &&
                                  completeDate(_text(row, 'date')).isEmpty
                              ? l.processingDateRequired
                              : null,
                        ),
                      ),
                    ),
                  AppSelect<AnalysisCategory>(
                    label: l.localCategory,
                    value: _category[row.id]!,
                    options: [
                      for (final c in AnalysisCategory.values)
                        AppSelectOption(
                          value: c,
                          label: categoryPresentation(context, c).title,
                        ),
                    ],
                    onChanged: disabled
                        ? null
                        : (c) {
                            _category[row.id] = c;
                            _changed();
                          },
                  ),
                  const SizedBox(height: 16),
                  AppSelect<ResultValueKind>(
                    label: l.localValueKind,
                    value: _kind[row.id]!,
                    options: [
                      for (final k in ResultValueKind.values)
                        AppSelectOption(
                          value: k,
                          label: switch (k) {
                            ResultValueKind.numeric => l.localNumeric,
                            ResultValueKind.comparison => l.localComparison,
                            ResultValueKind.qualitative => l.localQualitative,
                            ResultValueKind.missing => l.localMissing,
                          },
                        ),
                    ],
                    onChanged: disabled
                        ? null
                        : (v) {
                            _kind[row.id] = v;
                            _changed();
                          },
                  ),
                  if (release != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      row.candidates.length > 1
                          ? l.terminologyAmbiguous
                          : row.candidates.isEmpty
                          ? l.terminologyUnknown
                          : l.terminologySuggestion(
                              release
                                  .indicator(row.candidates.single)!
                                  .label
                                  .inLanguage(language),
                            ),
                    ),
                    AppSelect<String>(
                      label: l.terminologyIndicator,
                      value: _indicator[row.id]!,
                      options: [
                        AppSelectOption(
                          value: '',
                          label: l.terminologyUnlinked,
                        ),
                        for (final c in release.indicators)
                          AppSelectOption(
                            value: c.id,
                            label: c.label.inLanguage(language),
                          ),
                      ],
                      onChanged: disabled
                          ? null
                          : (v) {
                              _indicator[row.id] = v;
                              _unit[row.id] = '';
                              _changed();
                            },
                    ),
                    if (_indicator[row.id]!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AppSelect<String>(
                        label: l.terminologyUnit,
                        value: _unit[row.id]!,
                        options: [
                          AppSelectOption(
                            value: '',
                            label: l.terminologyUnlinked,
                          ),
                          for (final id
                              in release
                                  .indicator(_indicator[row.id]!)!
                                  .unitIds)
                            if (release
                                    .findUnits(_text(row, 'unit'))
                                    .conceptIds
                                    .isEmpty ||
                                release
                                    .findUnits(_text(row, 'unit'))
                                    .conceptIds
                                    .contains(id))
                              AppSelectOption(
                                value: id,
                                label: release.unit(id)!.symbol,
                              ),
                        ],
                        onChanged: disabled || _text(row, 'unit').isEmpty
                            ? null
                            : (v) {
                                _unit[row.id] = v;
                                _changed();
                              },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        if (!d.confirmed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  key: const Key('draft-add'),
                  onPressed: disabled || d.rows.length >= 20 ? null : _addRow,
                  child: Text(l.processingAddRow),
                ),
                OutlinedButton(
                  key: const Key('draft-save'),
                  onPressed: disabled ? null : () => _save(false),
                  child: Text(l.processingSaveDraft),
                ),
                FilledButton(
                  key: const Key('draft-confirm'),
                  onPressed: disabled || d.rows.isEmpty
                      ? null
                      : () => _save(true),
                  child: Text(l.processingConfirm),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
