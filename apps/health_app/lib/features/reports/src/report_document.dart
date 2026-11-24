import 'dart:convert';

import 'package:medical_domain/medical_domain.dart';

import '../../../presentation/record_fields.dart';
import '../../../l10n/generated/app_localizations.dart';

String reportDocument(HealthReport report, AppLocalizations l) {
  String esc(String text) => const HtmlEscape().convert(text);
  String section(String title, Iterable<HealthRecord> records) =>
      '<section><h2>${esc(title)}</h2>${records.map((r) => '<article>${recordFields(l, r).where((f) => f.$2.isNotEmpty).map((f) => '<p><strong>${esc(f.$1)}:</strong> ${esc(f.$2)}</p>').join()}${r is LabResult && r.documentSource != null ? '<p>${esc(l.reportOriginal)}: ${esc(r.documentSource!.fields['evidence'] ?? '')}</p>' : ''}</article>').join()}</section>';
  return '''<!doctype html><html lang="${esc(l.localeName)}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(l.reportTitle)}</title><style>body{font:16px system-ui,sans-serif;line-height:1.5;margin:2rem auto;padding:0 1rem;max-width:900px;color:#202020}h1,h2{line-height:1.2}article{border-top:1px solid #bbb;padding:1rem 0;break-inside:avoid}p{margin:.3rem 0;white-space:pre-wrap;overflow-wrap:anywhere}@media print{body{font-size:11pt;margin:0;max-width:none}h2{break-after:avoid}}</style><body><h1>${esc(l.reportTitle)}</h1><p>${report.period.start} — ${report.period.end}</p><p>${esc(l.reportScope)}</p>${section(l.profile, report.profile == null ? [] : [report.profile!])}${section(l.localResults, report.results)}${section(l.localMedications, report.medications)}${section(l.localMeasurements, report.measurements)}<footer>${esc(l.reportNoInterpretation)}</footer></body></html>''';
}

String reportText(HealthReport report, AppLocalizations l) {
  final lines = <String>[
    l.reportTitle,
    '${report.period.start} — ${report.period.end}',
    l.reportScope,
  ];
  void section(String title, Iterable<HealthRecord> records) {
    lines.add('\n$title');
    for (final r in records) {
      for (final field in recordFields(l, r)) {
        if (field.$2.isNotEmpty) lines.add('${field.$1}: ${field.$2}');
      }
      if (r is LabResult && r.documentSource != null) {
        lines.add(
          '${l.reportOriginal}: ${r.documentSource!.fields['evidence'] ?? ''}',
        );
      }
      lines.add('');
    }
  }

  section(l.profile, report.profile == null ? [] : [report.profile!]);
  section(l.localResults, report.results);
  section(l.localMedications, report.medications);
  section(l.localMeasurements, report.measurements);
  lines.add(l.reportNoInterpretation);
  return lines.join('\n');
}
