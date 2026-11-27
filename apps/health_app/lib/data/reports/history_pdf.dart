import 'dart:ui' show Locale;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/history/history.dart';

import 'package:medical_domain/medical_domain.dart';

import '../../l10n/generated/app_localizations.dart';

/// Local PDF generation. Fonts are bundled; no document or font is sent to an
/// external service. The platform receives only the frozen selected snapshot.
Future<Uint8List> buildHistoryPdf(
  HistoryPrintSnapshot report,
  String language,
) async {
  final l = lookupAppLocalizations(Locale(language));
  final font = pw.Font.ttf(
    await rootBundle.load(
      'packages/design_system/assets/fonts/Manrope-Regular.ttf',
    ),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load(
      'packages/design_system/assets/fonts/Manrope-Bold.ttf',
    ),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: font,
      bold: bold,
      italic: font,
      boldItalic: bold,
    ),
  );
  String date(CalendarDate d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${(d.year % 100).toString().padLeft(2, '0')}';
  final dates = report.dates;
  // Page batches prevent an arbitrarily long history making unreadable columns.
  for (var first = 0; first < (dates.isEmpty ? 1 : dates.length); first += 9) {
    final batch = dates.skip(first).take(9).toList();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 500,
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l.analysisHistory,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (report.isDemo)
                pw.Text(l.demoTitle, style: const pw.TextStyle(fontSize: 10)),
              if (report.profile.isNotEmpty)
                pw.Text(report.profile, style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                '${report.period.start} — ${report.period.end}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: [
              l.indicator,
              l.pdfUnit,
              l.pdfReference,
              for (final d in batch) date(d),
            ],
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(4),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xfff0edfb),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.6),
              1: const pw.FlexColumnWidth(.8),
              2: const pw.FlexColumnWidth(1.2),
            },
            data: [
              for (final row in report.rows)
                [
                  row.name,
                  row.points.map((p) => p.unit).toSet().join('\n'),
                  row.points.map((p) => p.reference).toSet().join('\n'),
                  for (final d in batch)
                    row.points
                        .where((p) => p.date == d)
                        .map(
                          (p) =>
                              '${p.value}${p.status == 'high'
                                  ? ' ↑'
                                  : p.status == 'low'
                                  ? ' ↓'
                                  : ''}',
                        )
                        .join('\n'),
                ],
            ],
          ),
          if (first == 0) ...[
            pw.SizedBox(height: 12),
            for (final row in report.rows)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  '${row.name}${row.context.isEmpty ? '' : ' · ${row.context}'}\n${row.points.map((p) => '${p.date}: ${p.value} ${p.unit} · ${p.reference} · ${p.source}${p.details.isEmpty ? '' : ' · ${p.details}'}').join('\n')}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            if (report.events.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                l.historyPeriodEvents,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              for (final e in report.events)
                pw.Text(
                  '${e.start} — ${e.end ?? '—'} · ${e.name} · ${e.detail}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ],
        ],
      ),
    );
  }
  return doc.save();
}

Future<bool> exportHistoryPdf(
  HistoryPrintSnapshot snapshot,
  String language,
  bool share,
) async {
  final bytes = await buildHistoryPdf(snapshot, language);
  const filename = 'analysis-history.pdf';
  if (share) return Printing.sharePdf(bytes: bytes, filename: filename);
  final file = XFile.fromData(
    bytes,
    mimeType: 'application/pdf',
    name: filename,
  );
  if (kIsWeb) {
    await file.saveTo(filename);
    return true;
  }
  if ([
    TargetPlatform.android,
    TargetPlatform.iOS,
  ].contains(defaultTargetPlatform)) {
    return Printing.layoutPdf(
      name: filename,
      format: PdfPageFormat.a4.landscape,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }
  final destination = await getSaveLocation(suggestedName: filename);
  if (destination == null) return false;
  await file.saveTo(destination.path);
  return true;
}
