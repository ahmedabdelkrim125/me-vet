import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import 'models/representative_report_model.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';

class ReportPdfBuilder {
  ReportPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(RepresentativeReportModel report) async {
    final document = pw.Document();

    final regularFontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

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
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildTitle(boldFont),
          pw.SizedBox(height: 22),
          _buildMetaRow(report, boldFont),
          pw.SizedBox(height: 24),
          if (report.warnings.isNotEmpty) ...[
            _buildWarnings(report.warnings, boldFont, regularFont),
            pw.SizedBox(height: 18),
          ],
          ..._buildSummarySection(report, boldFont, regularFont),
          ..._buildSalesSection(report, boldFont, regularFont),
          ..._buildBalancesSection(report, boldFont, regularFont),
          if (report.collectionsByCustomer.isNotEmpty)
            ..._buildCollectionsSection(report, boldFont, regularFont),
          if (report.expenses.isNotEmpty)
            ..._buildExpensesSection(report, boldFont, regularFont),
          if (report.returns.isNotEmpty)
            ..._buildReturnsSection(report, boldFont, regularFont),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildTitle(pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        'تقرير التحصيلات',
        style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
      ),
    );
  }

  static pw.Widget _buildMetaRow(
      RepresentativeReportModel data, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'الفترة من : ${_formatDate(data.from)}',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'إلى : ${_formatDate(data.to)}',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
          ],
        ),
        pw.Text(
          'تاريخ التقرير : ${_formatDate(DateTime.now())}',
          style: pw.TextStyle(font: boldFont, fontSize: 11),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: _green, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildWarnings(
    List<String> warnings,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange800, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تنبيه: بعض بيانات التقرير غير مكتملة',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.orange800,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final warning in warnings)
                  pw.Text(
                    warning,
                    style: pw.TextStyle(font: regularFont, fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildSummarySection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'إجمالي المصروفات',
      'إجمالي التحصيل',
    ];
    final values = [
      '${report.totalExpenses.toStringAsFixed(2)} ج.م',
      '${report.totalCollections.toStringAsFixed(2)} ج.م',
    ];

    return _buildSection(
      'ملخص التقرير',
      headers,
      [values],
      boldFont,
      regularFont,
    );
  }

  static List<pw.Widget> _buildSalesSection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'صافي المبيعات',
      'إجمالي المرتجعات',
      'إجمالي المبيعات',
    ];
    final values = [
      '${report.netSales.toStringAsFixed(2)} ج.م',
      '${report.totalReturns.toStringAsFixed(2)} ج.م',
      '${report.totalSales.toStringAsFixed(2)} ج.م',
    ];

    return _buildSection(
      'المبيعات والمرتجعات',
      headers,
      [values],
      boldFont,
      regularFont,
    );
  }

  static List<pw.Widget> _buildBalancesSection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'بعد المصروفات',
      'المصروفات',
      'قبل المصروفات',
      'وسيلة الدفع',
    ];
    final rows = <List<String>>[];

    void addBalanceRow(String methodLabel, String methodKey) {
      if (report.invalidBalanceMethods.contains(methodKey)) {
        rows.add(['-', '-', '-', methodLabel]);
        return;
      }
      final b = report.balances[methodKey];
      if (b != null) {
        rows.add([
          b.afterExpenses.toStringAsFixed(2),
          b.expenses.toStringAsFixed(2),
          b.beforeExpenses.toStringAsFixed(2),
          methodLabel,
        ]);
      } else {
        rows.add(['0.00', '0.00', '0.00', methodLabel]);
      }
    }

    addBalanceRow('كاش', 'cash');
    addBalanceRow('فودافون كاش', 'vodafone_cash');
    addBalanceRow('InstaPay', 'instapay');

    return _buildSection(
      'الأرصدة الحالية',
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
    );
  }

  static List<pw.Widget> _buildCollectionsSection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['إجمالي التحصيل', 'اسم العميل', 'م'];
    final rows = <List<String>>[];

    for (var i = 0; i < report.collectionsByCustomer.length; i++) {
      final c = report.collectionsByCustomer[i];
      rows.add([
        '${c.totalCollected.toStringAsFixed(2)} ج.م',
        c.customerName,
        '${i + 1}',
      ]);
    }

    return _buildSection(
      'تحصيلات العملاء',
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(0.6),
      },
    );
  }

  static List<pw.Widget> _buildExpensesSection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['وسيلة الدفع', 'المبلغ', 'التصنيف', 'م'];
    final rows = <List<String>>[];

    for (var i = 0; i < report.expenses.length; i++) {
      final e = report.expenses[i];
      rows.add([
        _formatMethod(e.paymentMethod),
        '${e.amount.toStringAsFixed(2)} ج.م',
        e.category,
        '${i + 1}',
      ]);
    }

    return _buildSection(
      'المصروفات',
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(0.6),
      },
    );
  }

  static List<pw.Widget> _buildReturnsSection(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['المبلغ', 'السبب', 'العميل', 'رقم المرتجع', 'م'];
    final rows = <List<String>>[];

    for (var i = 0; i < report.returns.length; i++) {
      final r = report.returns[i];
      final reason = r.reason?.trim() ?? '';
      rows.add([
        '${r.amount.toStringAsFixed(2)} ج.م',
        reason.isEmpty ? '-' : reason,
        r.customerName,
        r.code.isEmpty ? '-' : r.code,
        '${i + 1}',
      ]);
    }

    return _buildSection(
      'تفاصيل المرتجعات',
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.4),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(0.6),
      },
    );
  }

  static List<pw.Widget> _buildSection(
    String title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont, {
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return [
      pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green),
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.6),
        columnWidths: columnWidths,
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: _navy),
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: pw.Text(
                      h,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10,
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
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: pw.Text(
                        cell,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      pw.SizedBox(height: 18),
    ];
  }

  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatMethod(String method) {
    switch (method) {
      case 'cash':
        return 'كاش';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'InstaPay';
      default:
        return method;
    }
  }
}
