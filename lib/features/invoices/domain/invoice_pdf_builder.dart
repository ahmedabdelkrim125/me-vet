import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';

class InvoicePdfLineItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  const InvoicePdfLineItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

/// One older invoice paid off together with the current invoice's own
/// payment, as part of the same collection.
class InvoicePdfOldDebtLine {
  final String invoiceCode;
  final double amount;

  const InvoicePdfOldDebtLine({
    required this.invoiceCode,
    required this.amount,
  });
}

class InvoicePdfData {
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String repName;
  final List<InvoicePdfLineItem> items;
  final double invoiceTotal;
  final double previousBalance;
  final double totalDue;
  final double paidNow;
  final double remaining;
  final double discountAmount;

  /// Older invoices collected together with this invoice's own payment, if
  /// any (e.g. the customer had an old debt and it was collected alongside
  /// this invoice in one payment).
  final List<InvoicePdfOldDebtLine> oldDebtCollected;

  const InvoicePdfData({
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.repName,
    required this.items,
    required this.invoiceTotal,
    required this.previousBalance,
    required this.totalDue,
    required this.paidNow,
    required this.remaining,
    this.discountAmount = 0,
    this.oldDebtCollected = const [],
  });

  bool get hasDiscount => discountAmount > 0.005;

  double get subtotalBeforeDiscount => invoiceTotal + discountAmount;

  double get discountPercent =>
      subtotalBeforeDiscount > 0 ? discountAmount / subtotalBeforeDiscount * 100 : 0;

  double get oldDebtTotal =>
      oldDebtCollected.fold(0.0, (sum, l) => sum + l.amount);
}

class InvoicePdfBuilder {
  InvoicePdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(InvoicePdfData data) async {
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
          buildBackground: (context) =>
              buildWhitePdfBackground(watermarkBytes: null),
        ),
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: _buildFooter(),
        ),
        build: (context) {
          final chunks = paginateItems(data.items);
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildTitle(data, boldFont),
                  pw.SizedBox(height: 22),
                  _buildMetaRow(data, boldFont),
                  pw.SizedBox(height: 18),
                  ..._buildChunkWidgets(chunks, boldFont, regularFont),
                  pw.SizedBox(height: 16),
                  if (data.hasDiscount) ...[
                    _buildDiscountTable(data, boldFont, regularFont),
                    pw.SizedBox(height: 14),
                  ],
                  _buildSummaryTable(data, boldFont, regularFont),
                  if (data.oldDebtCollected.isNotEmpty) ...[
                    pw.SizedBox(height: 14),
                    _buildOldDebtTable(data, boldFont, regularFont),
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

  static pw.Widget _buildTitle(InvoicePdfData data, pw.Font boldFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'فاتورة مبيعات',
            style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'No. ${data.invoiceNumber}',
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: _green),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRow(InvoicePdfData data, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'العميل / ${data.customerName}',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'اسم المندوب / ${data.repName}',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
          ],
        ),
        pw.Text(
          'التاريخ : ${_formatDate(data.date)}',
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

  static pw.Widget _buildItemsTable(
    List<InvoicePdfLineItem> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['الإجمالي', 'السعر', 'العدد', 'الصنف / المنتج', 'م'];

    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add([
        item.total.toStringAsFixed(0),
        item.price.toStringAsFixed(0),
        '${item.quantity}',
        item.name,
        '${i + 1}',
      ]);
    }
    return _buildStyledTable(
      null,
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(3.4),
        4: pw.FlexColumnWidth(0.6),
      },
    );
  }

  static List<List<InvoicePdfLineItem>> paginateItems(
      List<InvoicePdfLineItem> items,
      [int size = 15]) {
    final chunks = <List<InvoicePdfLineItem>>[];
    for (var start = 0; start < items.length; start += size) {
      final end = (start + size).clamp(0, items.length);
      chunks.add(items.sublist(start, end));
    }
    return chunks.isEmpty ? [const []] : chunks;
  }

  static List<pw.Widget> _buildChunkWidgets(
    List<List<InvoicePdfLineItem>> chunks,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final widgets = <pw.Widget>[];
    for (var index = 0; index < chunks.length; index++) {
      if (index > 0) widgets.add(pw.NewPage());
      widgets.add(_buildItemsTable(chunks[index], boldFont, regularFont));
    }
    return widgets;
  }

  /// ملخص الفاتورة: نفس أسلوب باقي الـ PDFs في التطبيق (عنوان أخضر فوق،
  /// وجدول رفيع بهيدر كحلي وصف قيم واحد) بدل مربعات كبيرة منفصلة.
  static pw.Widget _buildSummaryTable(
    InvoicePdfData data,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final hasOldDebt = data.oldDebtCollected.isNotEmpty;

    final headers = [
      'المتبقي على العميل',
      if (hasOldDebt) 'دين قديم متحصّل معها',
      'المدفوع من الفاتورة',
      'إجمالي المستحق على العميل',
      'الحساب السابق',
      'قيمة الفاتورة الحالية',
    ];
    final values = [
      _formatAmount(data.remaining),
      if (hasOldDebt) _formatAmount(data.oldDebtTotal),
      _formatAmount(data.paidNow),
      _formatAmount(data.totalDue),
      _formatAmount(data.previousBalance),
      _formatAmount(data.invoiceTotal),
    ].map((v) => '$v ج.م').toList();

    return _buildStyledTable(
        'ملخص الفاتورة', headers, [values], boldFont, regularFont);
  }

  static pw.Widget _buildDiscountTable(
    InvoicePdfData data,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'نسبة الخصم',
      'قيمة الخصم',
      'الإجمالي قبل الخصم',
    ];
    final values = [
      '${_formatPercent(data.discountPercent)}%',
      '${_formatAmount(data.discountAmount)} ج.م',
      '${_formatAmount(data.subtotalBeforeDiscount)} ج.م',
    ];

    return _buildStyledTable(
        'الخصم', headers, [values], boldFont, regularFont);
  }

  static String _formatPercent(double value) {
    var text = value.toStringAsFixed(2);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  /// نفس أسلوب "تحصيلات العملاء" في تقرير المندوب اليومي.
  static pw.Widget _buildOldDebtTable(
    InvoicePdfData data,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['المبلغ', 'الفاتورة القديمة', 'م'];
    final rows = <List<String>>[
      for (var i = 0; i < data.oldDebtCollected.length; i++)
        [
          '${_formatAmount(data.oldDebtCollected[i].amount)} ج.م',
          data.oldDebtCollected[i].invoiceCode,
          '${i + 1}',
        ],
    ];

    return _buildStyledTable(
      'دين قديم اتحصّل مع الفاتورة دي',
      headers,
      rows,
      boldFont,
      regularFont,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.6),
        2: pw.FlexColumnWidth(0.6),
      },
    );
  }

  /// الجدول الموحّد المستخدم في كل الـ PDFs بالتطبيق: عنوان أخضر (اختياري)،
  /// جدول بهيدر كحلي وصفوف رفيعة.
  static pw.Widget _buildStyledTable(
    String? title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont, {
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green),
          ),
          pw.SizedBox(height: 8),
        ],
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
                          vertical: 6, horizontal: 4),
                      child: pw.Text(
                        h,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9.5,
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
                            vertical: 6, horizontal: 4),
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

  static String _formatAmount(double value) {
    final whole = value.abs().truncate();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    var out = (value < 0 ? '-' : '') + buffer.toString();
    final decimals = (value.abs() - whole);
    if (decimals > 0.005) {
      out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
    }
    return out;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
