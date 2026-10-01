import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'customer_statement.dart';
import 'entities/customer_transaction.dart';
import 'entities/payment_breakdown.dart';

class CustomerStatementPdfBuilder {
  CustomerStatementPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build({
    required String customerName,
    required CustomerStatement statement,
    List<PaymentBreakdown> payments = const [],
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

    // Keyed by the payment's own code, so each payment transaction row can
    // look up how it was split between its own invoice and older debt.
    final paymentsByCode = <String, PaymentBreakdown>{
      for (final p in payments) p.code: p,
    };

    document.addPage(
      pw.MultiPage(
        // A big statement must be allowed to flow over many pages.
        maxPages: 200,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          // Applies to the whole document. Do NOT wrap the content in a
          // pw.Directionality widget: it cannot be split across pages, so a
          // long table throws TooManyPagesException.
          textDirection: pw.TextDirection.rtl,
          buildBackground: (context) =>
              buildWhitePdfBackground(watermarkBytes: null),
        ),
        footer: (context) => pw.Column(
          children: [pw.Divider(color: _green, thickness: 1)],
        ),
        // Top-level children of MultiPage: the table is splittable, so it
        // continues on the next page (its header row repeats).
        build: (context) => [
          _buildTitle(customerName, boldFont),
          pw.SizedBox(height: 14),
          pw.Text(
            'الفترة: من ${_date(statement.periodStart)} إلى ${_date(statement.periodEnd)}',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 14),
          _buildSummary(statement, boldFont, regularFont),
          pw.SizedBox(height: 18),
          _buildTable(statement.transactions, paymentsByCode, boldFont, regularFont),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildTitle(String customerName, pw.Font boldFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'كشف حساب العميل',
            style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            customerName,
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: _green),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(
    CustomerStatement s,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    pw.Widget box(String label, double value, {bool highlight = false}) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.6),
            color: highlight ? _navy : null,
          ),
          child: pw.Column(
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 8,
                      color: highlight ? PdfColors.white : PdfColors.grey700)),
              pw.SizedBox(height: 3),
              pw.Text('${_money(value)} ج.م',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: highlight ? PdfColors.white : _navy)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        box('الرصيد في بداية الفترة', s.openingBalance),
        box('إجمالي المدين', s.totalDebit),
        box('إجمالي الدائن', s.totalCredit),
        box('الرصيد الحالي', s.closingBalance, highlight: true),
      ],
    );
  }

  static pw.Widget _buildTable(
    List<CustomerTransaction> transactions,
    Map<String, PaymentBreakdown> paymentsByCode,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'الرصيد بعدها',
      'دائن',
      'مدين',
      'الوقت',
      'التاريخ',
      'المرجع',
      'النوع'
    ];

    final rows = transactions.map((t) {
      final d = t.occurredAt.toLocal();
      final time =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return (
        balanceAfter: _money(t.balanceAfter),
        credit: t.credit > 0 ? _money(t.credit) : '-',
        debit: t.debit > 0 ? _money(t.debit) : '-',
        time: time,
        date: _date(d),
        reference: _referenceText(t, paymentsByCode),
        type: t.type.label,
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(0.9),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(2.2),
        6: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _navy),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 3),
                    child: pw.Text(
                      h,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: boldFont, fontSize: 8, color: PdfColors.white),
                    ),
                  ))
              .toList(),
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              _cell(row.balanceAfter, regularFont),
              _cell(row.credit, regularFont),
              _cell(row.debit, regularFont),
              _cell(row.time, regularFont),
              _cell(row.date, regularFont),
              _cell(row.reference, regularFont),
              _cell(row.type, regularFont),
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  /// The transaction's reference code, plus — for a payment split between the
  /// invoice issued with it and older debt — one extra line per invoice it
  /// was applied to, so the breakdown is visible without leaving the table.
  static String _referenceText(
    CustomerTransaction t,
    Map<String, PaymentBreakdown> paymentsByCode,
  ) {
    final code = t.referenceCode ?? '-';
    if (t.type != CustomerTransactionType.payment) return code;

    final breakdown = paymentsByCode[t.referenceCode];
    if (breakdown == null || breakdown.lines.length < 2) return code;

    final lines = [code];
    for (final line in breakdown.lines) {
      final label = line.isOwnInvoice ? 'فاتورة' : 'دين قديم';
      final target = line.invoiceCode ?? 'رصيد سابق';
      lines.add('$label $target: ${_money(line.amount)}');
    }
    return lines.join('\n');
  }

  static String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  /// Whole numbers without decimals, otherwise two decimals.
  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
