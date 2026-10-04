import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';

class DailyInvoicePdfEntry {
  final String invoiceCode;
  final String customerName;
  final DateTime date;
  final List<({String name, int quantity, double price, double total})> items;
  final double total;
  final String status;

  const DailyInvoicePdfEntry({
    required this.invoiceCode,
    required this.customerName,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
  });
}

/// كل فواتير اليوم في ملف واحد، بنفس أسلوب باقي الـ PDFs في التطبيق: عنوان
/// أخضر فوق كل جدول، هيدر كحلي رفيع.
class DailyInvoicesPdfBuilder {
  DailyInvoicesPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(
    List<DailyInvoicePdfEntry> entries,
    DateTime reportDate,
  ) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final totalAmount = entries.fold(0.0, (sum, e) => sum + e.total);

    document.addPage(
      pw.MultiPage(
        maxPages: 500,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          textDirection: pw.TextDirection.rtl,
          buildBackground: (context) =>
              buildWhitePdfBackground(watermarkBytes: null),
        ),
        footer: (context) => pw.Column(
          children: [pw.Divider(color: _green, thickness: 1)],
        ),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'الفواتير اليومية',
                  style:
                      pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _formatDate(reportDate),
                  style:
                      pw.TextStyle(font: boldFont, fontSize: 11, color: _green),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildTable(
            null,
            ['عدد الفواتير', 'إجمالي اليوم'],
            [
              ['${entries.length}', '${_formatAmount(totalAmount)} ج.م'],
            ],
            boldFont,
            regularFont,
          ),
          pw.SizedBox(height: 18),
          for (final entry in entries) ...[
            _buildInvoiceSection(entry, boldFont, regularFont),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildInvoiceSection(
    DailyInvoicePdfEntry entry,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['الإجمالي', 'السعر', 'العدد', 'الصنف'];
    final rows = [
      for (final item in entry.items)
        [
          _formatAmount(item.total),
          _formatAmount(item.price),
          '${item.quantity}',
          item.name,
        ],
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${entry.invoiceCode}  —  ${entry.customerName}',
                style: pw.TextStyle(font: boldFont, fontSize: 11, color: _navy),
              ),
              pw.Text(
                '${_formatAmount(entry.total)} ج.م  (${entry.status})',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _formatTime(entry.date),
            style: pw.TextStyle(
                font: regularFont, fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          _buildTable(null, headers, rows, boldFont, regularFont),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(
    String? title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          pw.Text(title,
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green)),
          pw.SizedBox(height: 8),
        ],
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.6),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _navy),
              children: headers
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        child: pw.Text(h,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                                color: PdfColors.white)),
                      ))
                  .toList(),
            ),
            for (final row in rows)
              pw.TableRow(
                children: row
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 5, horizontal: 4),
                          child: pw.Text(cell,
                              textAlign: pw.TextAlign.center,
                              style:
                                  pw.TextStyle(font: regularFont, fontSize: 9)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ],
    );
  }

  static String _formatAmount(double value) {
    final whole = value.abs().truncate();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return (value < 0 ? '-' : '') + buffer.toString();
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
