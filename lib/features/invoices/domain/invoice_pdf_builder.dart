import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';

const _pdfOrange = 0xFFE0862F;

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
  });
}

class InvoicePdfBuilder {
  InvoicePdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);
  static const _orange = PdfColor.fromInt(_pdfOrange);

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
                  pw.SizedBox(height: 18),
                  _buildTotalsTable(data, boldFont),
                  _buildPaymentStatusNote(data, boldFont),
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
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(3.4),
        4: pw.FlexColumnWidth(0.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _navy),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 5,
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
                      vertical: 5,
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

  static pw.Widget _buildTotalsTable(InvoicePdfData data, pw.Font boldFont) {
    final rows = <(String, double)>[
      ('قيمة الفاتورة الحالية', data.invoiceTotal),
      ('الحساب السابق', data.previousBalance),
      ('إجمالي المستحق على العميل', data.totalDue),
      ('المدفوع الآن', data.paidNow),
      ('المتبقي على العميل', data.remaining),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: pw.Text(
                  rows[i].$1,
                  textAlign: pw.TextAlign.start,
                  style: pw.TextStyle(font: boldFont, fontSize: 10.5),
                ),
              ),
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: pw.Text(
                  '${_formatAmount(rows[i].$2)} ج.م',
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// نفس تفاصيل الحساب الظاهرة في شاشة الفاتورة:
  /// حالة التحصيل (مسدد بالكامل / تحصيل جزئي / آجلة بدون تحصيل).
  static pw.Widget _buildPaymentStatusNote(
      InvoicePdfData data, pw.Font boldFont) {
    final fullyPaid = (data.remaining.abs() <= 0.01) && data.paidNow > 0;
    final fullyDeferred = data.paidNow <= 0.005;

    String note;
    PdfColor color;
    if (fullyPaid) {
      note = 'تم تحصيل كامل المبلغ المستحق — الحساب مسدد بالكامل';
      color = _green;
    } else if (fullyDeferred) {
      note =
          'لم يتم تحصيل أي مبلغ — الفاتورة آجلة بالكامل والمبلغ مستحق على العميل';
      color = _orange;
    } else {
      note =
          'تم تحصيل جزء من المبلغ — المتبقي (${_formatAmount(data.remaining)} ج.م) مستحق على العميل';
      color = _orange;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: _tint(color, 0.12),
        border: pw.Border.all(color: _tint(color, 0.45)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 7,
            height: 7,
            decoration:
                pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              note,
              style: pw.TextStyle(font: boldFont, fontSize: 10, color: color),
            ),
          ),
        ],
      ),
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

  static PdfColor _tint(PdfColor color, double opacity) {
    return PdfColor.fromInt(
      color.toInt() & 0x00FFFFFF | ((opacity * 255).round() << 24),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
