import 'dart:convert';

import '../../../l10n/generated/app_localizations.dart';
import 'history_view_model.dart';

/// Uses the same filtered rows, dates and events as the on-screen viewer.
String historyDocument(
  HistoryViewModel model,
  AppLocalizations l, {
  String profile = '',
}) {
  String esc(String value) => const HtmlEscape().convert(value);
  final dates = model.dates;
  final rows = model.rows
      .map(
        (row) =>
            '<tr><th>${esc(row.name)}<small>${esc(row.context)}</small></th>${dates.map((date) => '<td>${model.points(row, date).map((p) => '${esc(p.value)} ${esc(p.unit)}<small>${esc(p.source)} · ${esc(p.reference)}</small>${p.details.isEmpty ? '' : '<small>${esc(p.details)}</small>'}').join('<hr>')}</td>').join()}</tr>',
      )
      .join();
  return '''<!doctype html><html lang="${esc(l.localeName)}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(l.analysisHistory)}</title><style>@page{size:landscape;margin:12mm}body{font:14px system-ui;color:#1c1930;margin:20px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:8px;text-align:left;vertical-align:top}small{display:block;font-weight:normal}thead{display:table-header-group}tr{break-inside:avoid}button{padding:10px}@media print{button{display:none}body{margin:0}}h1{font-size:22px}</style><body><button onclick="window.print()">${esc(l.historyPrint)}</button><h1>${esc(l.analysisHistory)}</h1>${model.data.isDemo ? '<p>${esc(l.demoTitle)}</p>' : ''}<p>${esc(profile)}</p><p>${model.period.start} — ${model.period.end}</p><table><thead><tr><th>${esc(l.indicator)}</th>${dates.map((d) => '<th>$d</th>').join()}</tr></thead><tbody>$rows</tbody></table>${model.showEvents ? '<h2>${esc(l.historyEvents)}</h2><ul>${model.events.map((e) => '<li>${e.start}${e.end == null ? '' : ' — ${e.end}'} · ${esc(e.name)} · ${esc(e.detail)}</li>').join()}</ul>' : ''}<footer>${esc(l.reportNoInterpretation)}</footer></body></html>''';
}

String historyText(
  HistoryViewModel model,
  AppLocalizations l, {
  String profile = '',
}) => [
  l.analysisHistory,
  if (model.data.isDemo) l.demoTitle,
  profile,
  '${model.period.start} — ${model.period.end}',
  for (final row in model.rows) ...[
    '${row.name} · ${row.context}',
    for (final point in row.points.where((p) => model.period.includes(p.date)))
      '${point.date}: ${point.value} ${point.unit} · ${point.reference} · ${point.source} · ${point.details}',
  ],
  if (model.showEvents)
    for (final event in model.events)
      '${event.start}${event.end == null ? '' : ' — ${event.end}'}: ${event.name} · ${event.detail}',
  l.reportNoInterpretation,
].where((v) => v.isNotEmpty).join('\n');
