import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_colors.dart';
import 'report_section.dart';

pw.Widget buildReportSectionTable(
  ReportSection section,
  pw.Font boldFont,
  pw.Font regularFont,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(section.category,
          style:
              pw.TextStyle(font: boldFont, fontSize: 14, color: reportGreen)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: reportBorder, width: 0.6),
        columnWidths: section.columnWidths,
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: reportNavy),
            children: section.headers
                .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: pw.Text(
                        h,
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: PdfColors.white),
                      ),
                    ))
                .toList(),
          ),
          for (final row in section.rows)
            pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        child: pw.Text(
                          cell,
                          textAlign: pw.TextAlign.center,
                          maxLines: 2,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(font: regularFont, fontSize: 10),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    ],
  );
}
