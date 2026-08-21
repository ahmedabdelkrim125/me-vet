import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/const/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
  static const _companyContactNumber = '01091192831';

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

    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load(AppImages.logoSplash);
      logoBytes = logoData.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    Uint8List? watermarkBytes;
    try {
      final watermarkData = await rootBundle.load(AppImages.invoiceWatermark);
      watermarkBytes = watermarkData.buffer.asUint8List();
    } catch (_) {
      watermarkBytes = null;
    }

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          buildBackground: (context) {
            if (watermarkBytes == null) return pw.SizedBox();
            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 35),
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(watermarkBytes),
                  width: 320,
                ),
              ),
            );
          },
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(logoBytes, boldFont),
                pw.SizedBox(height: 18),
                _buildTitle(data, boldFont),
                pw.SizedBox(height: 22),
                _buildMetaRow(data, boldFont),
                pw.SizedBox(height: 18),
                _buildItemsTable(data, boldFont, regularFont),
                pw.SizedBox(height: 18),
                _buildTotalsTable(data, boldFont),
                pw.SizedBox(height: 26),
                _buildFooter(boldFont),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _buildHeader(Uint8List? logoBytes, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('تواصل معنا', style: _labelStyle(boldFont)),
            pw.SizedBox(height: 4),
            pw.Text(
              _companyContactNumber,
              style: _valueStyle(boldFont, _green),
            ),
          ],
        ),
        if (logoBytes != null)
          pw.Image(pw.MemoryImage(logoBytes), width: 90)
        else
          pw.Text(
            'MeVet',
            style: pw.TextStyle(font: boldFont, fontSize: 22, color: _navy),
          ),
      ],
    );
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

  static pw.Widget _buildFooter(pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Divider(color: _green, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'MeVet — For Animal Health',
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: _green),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    InvoicePdfData data,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['الإجمالي', 'السعر', 'العدد', 'الصنف / المنتج', 'م'];

    final rows = <List<String>>[];
    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      rows.add([
        item.total.toStringAsFixed(0),
        item.price.toStringAsFixed(0),
        '${item.quantity}',
        item.name,
        '${i + 1}',
      ]);
    }
    while (rows.length < 8) {
      rows.add(['', '', '', '', '${rows.length + 1}']);
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
                    vertical: 8,
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
                      vertical: 8,
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

  static pw.Widget _buildTotalsTable(InvoicePdfData data, pw.Font boldFont) {
    final headers = [
      'المبلغ المتبقي',
      'المبلغ المدفوع',
      'إجمالي الحساب',
      'الحساب السابق',
      'إجمالي الفاتورة',
    ];
    final values = [
      data.remaining.toStringAsFixed(0),
      data.paidNow.toStringAsFixed(0),
      data.totalDue.toStringAsFixed(0),
      data.previousBalance.toStringAsFixed(0),
      data.invoiceTotal.toStringAsFixed(0),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _navy),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
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
        pw.TableRow(
          children: values
              .map(
                (v) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: pw.Text(
                    '$v ج.م',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: _navy,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static pw.TextStyle _labelStyle(pw.Font boldFont) {
    return pw.TextStyle(font: boldFont, fontSize: 10, color: _navy);
  }

  static pw.TextStyle _valueStyle(pw.Font boldFont, PdfColor color) {
    return pw.TextStyle(font: boldFont, fontSize: 9, color: color);
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
