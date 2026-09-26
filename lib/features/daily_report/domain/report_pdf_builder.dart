import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'models/representative_report_model.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';

class ReportPdfBuilder {
  ReportPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(RepresentativeReportModel report) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
        'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf');
    final boldFontData = await rootBundle
        .load('assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          buildBackground: (context) =>
              buildWhitePdfBackground(watermarkBytes: null),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: _buildFooter(),
        ),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildTitle(boldFont),
                  pw.SizedBox(height: 22),
                  _buildMetaRow(report, boldFont),
                  pw.SizedBox(height: 24),
                  _buildSummaryTable(report, boldFont, regularFont),
                  pw.SizedBox(height: 18),
                  _buildBalancesTable(report, boldFont, regularFont),
                  pw.SizedBox(height: 18),
                  if (report.collectionsByCustomer.isNotEmpty) ...[
                    _buildCollectionsTable(report, boldFont, regularFont),
                    pw.SizedBox(height: 18),
                  ],
                  if (report.expenses.isNotEmpty) ...[
                    _buildExpensesTable(report, boldFont, regularFont),
                    pw.SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _buildTitle(pw.Font boldFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'تقرير المبيعات والتحصيلات',
            style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
          ),
        ],
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

  static pw.Widget _buildSummaryTable(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'إجمالي المصروفات',
      'عدد الفواتير',
      'إجمالي التحصيل',
      'إجمالي المبيعات'
    ];
    final values = [
      '${report.totalExpenses.toStringAsFixed(2)} ج.م',
      '${report.invoiceCount}',
      '${report.totalCollections.toStringAsFixed(2)} ج.م',
      '${report.totalSales.toStringAsFixed(2)} ج.م',
    ];

    return _buildStyledTable(
        'ملخص التقرير', headers, [values], boldFont, regularFont);
  }

  static pw.Widget _buildBalancesTable(
    RepresentativeReportModel report,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'وسيلة الدفع',
      'قبل المصروفات',
      'المصروفات',
      'بعد المصروفات'
    ];
    final rows = <List<String>>[];

    void addBalanceRow(String methodLabel, String methodKey) {
      final b = report.balances[methodKey];
      if (b != null) {
        rows.add([
          methodLabel,
          (b.beforeExpenses.toStringAsFixed(2)),
          (b.expenses.toStringAsFixed(2)),
          (b.afterExpenses.toStringAsFixed(2)),
        ]);
      } else {
        rows.add([methodLabel, '0.00', '0.00', '0.00']);
      }
    }

    addBalanceRow('كاش', 'cash');
    addBalanceRow('فودافون كاش', 'vodafone_cash');
    addBalanceRow('InstaPay', 'instapay');

    return _buildStyledTable(
        'الأرصدة الحالية', headers, rows, boldFont, regularFont,
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
        });
  }

  static pw.Widget _buildCollectionsTable(
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

    return _buildStyledTable(
        'تحصيلات العملاء', headers, rows, boldFont, regularFont,
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(0.6),
        });
  }

  static pw.Widget _buildExpensesTable(
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

    return _buildStyledTable('المصروفات', headers, rows, boldFont, regularFont,
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
          3: const pw.FlexColumnWidth(0.6),
        });
  }

  static pw.Widget _buildStyledTable(
    String title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont, {
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
      ],
    );
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
