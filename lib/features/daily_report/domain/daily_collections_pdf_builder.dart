import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'daily_collections_repository.dart';

class DailyCollectionsPdfBuilder {
  DailyCollectionsPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(
    List<DailyCollectionSummary> collections,
    DateTime reportDate,
  ) async {
    final regular = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final bold = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    final regularFont = pw.Font.ttf(regular);
    final boldFont = pw.Font.ttf(bold);

    final total = collections.fold(0.0, (sum, c) => sum + c.amount);
    double totalOf(PaymentMethod method) => collections
        .where((c) => c.method == method)
        .fold(0.0, (sum, c) => sum + c.amount);
    final cash = totalOf(PaymentMethod.cash);
    final vodafone = totalOf(PaymentMethod.vodafoneCash);
    final instapay = totalOf(PaymentMethod.instaPay);
    final other = total - cash - vodafone - instapay;

    final summaryHeaders = <String>[
      'إجمالي اليوم',
      if (other > 0.005) 'أخرى',
      'إنستا باي',
      'فودافون كاش',
      'نقدي',
      'عدد التحصيلات',
    ];
    final summaryValues = <String>[
      '${_formatAmount(total)} ج.م',
      if (other > 0.005) '${_formatAmount(other)} ج.م',
      '${_formatAmount(instapay)} ج.م',
      '${_formatAmount(vodafone)} ج.م',
      '${_formatAmount(cash)} ج.م',
      '${collections.length}',
    ];

    final rows = <List<String>>[
      for (var i = 0; i < collections.length; i++)
        [
          '${_formatAmount(collections[i].amount)} ج.م',
          collections[i].method?.displayLabel ?? '-',
          _formatTime(collections[i].date),
          collections[i].customerName,
          collections[i].code,
          '${i + 1}',
        ],
    ];

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        maxPages: 2000,
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
                  'التحصيلات اليومية',
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
          _buildTable(summaryHeaders, [summaryValues], boldFont, regularFont),
          pw.SizedBox(height: 18),
          _buildTable(
            ['المبلغ', 'طريقة الدفع', 'الوقت', 'العميل', 'رقم التحصيل', 'م'],
            rows,
            boldFont,
            regularFont,
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(1.3),
              2: pw.FlexColumnWidth(0.9),
              3: pw.FlexColumnWidth(2.6),
              4: pw.FlexColumnWidth(2.2),
              5: pw.FlexColumnWidth(0.5),
            },
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _buildTable(
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont, {
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _navy),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: pw.Text(
                    h,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        for (final row in rows)
          pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 5, horizontal: 4),
                    child: pw.Text(
                      cell,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: regularFont, fontSize: 9),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  static String _formatAmount(double value) {
    final whole = value.abs().truncate();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    var out = (value < 0 ? '-' : '') + buffer.toString();
    final decimals = value.abs() - whole;
    if (decimals > 0.005) {
      out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
    }
    return out;
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
