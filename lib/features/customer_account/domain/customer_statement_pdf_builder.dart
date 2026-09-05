import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'entities/customer_ledger.dart';
import 'entities/customer_transaction.dart';

/// Dedicated to the customer's full financial statement — a different
/// document from [InvoicePdfBuilder], which stays scoped to one invoice.
class CustomerStatementPdfBuilder {
  CustomerStatementPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build({
    required String customerName,
    required CustomerLedger ledger,
  }) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('كشف حساب العميل',
                    style: pw.TextStyle(font: boldFont, fontSize: 18, color: _navy)),
                pw.SizedBox(height: 6),
                pw.Text(customerName, style: pw.TextStyle(font: boldFont, fontSize: 13)),
                pw.SizedBox(height: 16),
                _buildTable(ledger.transactions, boldFont, regularFont),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'الرصيد الحالي: ${(ledger.currentBalance ?? 0).toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(font: boldFont, fontSize: 13, color: _navy),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildTable(
    List<CustomerTransaction> transactions,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['الرصيد بعدها', 'دائن', 'مدين', 'الوقت', 'التاريخ', 'المرجع', 'النوع'];

    final rows = transactions.map((t) {
      final d = t.occurredAt;
      final date =
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return [
        t.balanceAfter.toStringAsFixed(0),
        t.credit > 0 ? t.credit.toStringAsFixed(0) : '-',
        t.debit > 0 ? t.debit.toStringAsFixed(0) : '-',
        time,
        date,
        t.referenceCode ?? '-',
        t.type.label,
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _navy),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                    child: pw.Text(
                      h,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
                    ),
                  ))
              .toList(),
        ),
        for (final row in rows)
          pw.TableRow(
            children: row
                .map((cell) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                      child: pw.Text(
                        cell,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}