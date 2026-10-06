// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/pdf_page_background.dart';

// class InvoicePdfLineItem {
//   final String name;
//   final int quantity;
//   final double price;
//   final double total;

//   const InvoicePdfLineItem({
//     required this.name,
//     required this.quantity,
//     required this.price,
//     required this.total,
//   });
// }

// class InvoicePdfOldDebtLine {
//   final String invoiceCode;
//   final double amount;

//   const InvoicePdfOldDebtLine({
//     required this.invoiceCode,
//     required this.amount,
//   });
// }

// class InvoicePdfData {
//   final String invoiceNumber;
//   final DateTime date;
//   final String customerName;
//   final String repName;
//   final List<InvoicePdfLineItem> items;
//   final double invoiceTotal;
//   final double previousBalance;
//   final double totalDue;
//   final double paidNow;
//   final double remaining;
//   final double discountAmount;

//   final List<InvoicePdfOldDebtLine> oldDebtCollected;

//   const InvoicePdfData({
//     required this.invoiceNumber,
//     required this.date,
//     required this.customerName,
//     required this.repName,
//     required this.items,
//     required this.invoiceTotal,
//     required this.previousBalance,
//     required this.totalDue,
//     required this.paidNow,
//     required this.remaining,
//     this.discountAmount = 0,
//     this.oldDebtCollected = const [],
//   });

//   bool get hasDiscount => discountAmount > 0.005;

//   double get subtotalBeforeDiscount => invoiceTotal + discountAmount;

//   double get totalAfterDiscount => invoiceTotal;

//   double get discountPercent => subtotalBeforeDiscount > 0
//       ? discountAmount / subtotalBeforeDiscount * 100
//       : 0;

//   double get oldDebtTotal =>
//       oldDebtCollected.fold(0.0, (sum, l) => sum + l.amount);
// }

// class InvoicePdfBuilder {
//   InvoicePdfBuilder._();

//   static final _navy = PdfColor.fromInt(AppColors.primary.value);
//   static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
//   static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

//   static Future<Uint8List> build(InvoicePdfData data) async {
//     final document = pw.Document();

//     final regularFontData = await rootBundle.load(
//       'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
//     );
//     final boldFontData = await rootBundle.load(
//       'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
//     );
//     final regularFont = pw.Font.ttf(regularFontData);
//     final boldFont = pw.Font.ttf(boldFontData);

//     document.addPage(
//       pw.MultiPage(
//         pageTheme: pw.PageTheme(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(28),
//           theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
//           buildBackground: (context) =>
//               buildWhitePdfBackground(watermarkBytes: null),
//         ),
//         footer: (context) => pw.Directionality(
//           textDirection: pw.TextDirection.rtl,
//           child: _buildFooter(),
//         ),
//         build: (context) {
//           final chunks = paginateItems(data.items);
//           return [
//             pw.Directionality(
//               textDirection: pw.TextDirection.rtl,
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//                 children: [
//                   _buildTitle(data, boldFont),
//                   pw.SizedBox(height: 22),
//                   _buildMetaRow(data, boldFont),
//                   pw.SizedBox(height: 18),
//                   ..._buildChunkWidgets(chunks, boldFont, regularFont),
//                   pw.SizedBox(height: 16),
//                   _buildSummaryTable(data, boldFont, regularFont),
//                   if (data.oldDebtCollected.isNotEmpty) ...[
//                     pw.SizedBox(height: 14),
//                     _buildOldDebtTable(data, boldFont, regularFont),
//                   ],
//                 ],
//               ),
//             ),
//           ];
//         },
//       ),
//     );

//     return document.save();
//   }

//   static pw.Widget _buildTitle(InvoicePdfData data, pw.Font boldFont) {
//     return pw.Center(
//       child: pw.Column(
//         children: [
//           pw.Text(
//             'فاتورة مبيعات',
//             style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
//           ),
//           pw.SizedBox(height: 4),
//           pw.Text(
//             'No. ${data.invoiceNumber}',
//             style: pw.TextStyle(font: boldFont, fontSize: 11, color: _green),
//           ),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _buildMetaRow(InvoicePdfData data, pw.Font boldFont) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               'العميل / ${data.customerName}',
//               style: pw.TextStyle(font: boldFont, fontSize: 11),
//             ),
//             pw.SizedBox(height: 4),
//             pw.Text(
//               'اسم المندوب / ${data.repName}',
//               style: pw.TextStyle(font: boldFont, fontSize: 11),
//             ),
//           ],
//         ),
//         pw.Text(
//           'التاريخ : ${_formatDate(data.date)}',
//           style: pw.TextStyle(font: boldFont, fontSize: 11),
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildFooter() {
//     return pw.Column(
//       children: [
//         pw.Divider(color: _green, thickness: 1),
//       ],
//     );
//   }

//   static pw.Widget _buildItemsTable(
//     List<InvoicePdfLineItem> items,
//     pw.Font boldFont,
//     pw.Font regularFont,
//   ) {
//     final headers = ['الإجمالي', 'السعر', 'العدد', 'الصنف / المنتج', 'م'];

//     final rows = <List<String>>[];
//     for (var i = 0; i < items.length; i++) {
//       final item = items[i];
//       rows.add([
//         item.total.toStringAsFixed(0),
//         item.price.toStringAsFixed(0),
//         '${item.quantity}',
//         item.name,
//         '${i + 1}',
//       ]);
//     }
//     return _buildStyledTable(
//       null,
//       headers,
//       rows,
//       boldFont,
//       regularFont,
//       columnWidths: const {
//         0: pw.FlexColumnWidth(1.4),
//         1: pw.FlexColumnWidth(1.2),
//         2: pw.FlexColumnWidth(1),
//         3: pw.FlexColumnWidth(3.4),
//         4: pw.FlexColumnWidth(0.6),
//       },
//     );
//   }

//   static List<List<InvoicePdfLineItem>> paginateItems(
//       List<InvoicePdfLineItem> items,
//       [int size = 15]) {
//     final chunks = <List<InvoicePdfLineItem>>[];
//     for (var start = 0; start < items.length; start += size) {
//       final end = (start + size).clamp(0, items.length);
//       chunks.add(items.sublist(start, end));
//     }
//     return chunks.isEmpty ? [const []] : chunks;
//   }

//   static List<pw.Widget> _buildChunkWidgets(
//     List<List<InvoicePdfLineItem>> chunks,
//     pw.Font boldFont,
//     pw.Font regularFont,
//   ) {
//     final widgets = <pw.Widget>[];
//     for (var index = 0; index < chunks.length; index++) {
//       if (index > 0) widgets.add(pw.NewPage());
//       widgets.add(_buildItemsTable(chunks[index], boldFont, regularFont));
//     }
//     return widgets;
//   }

//   static pw.Widget _buildSummaryTable(
//     InvoicePdfData data,
//     pw.Font boldFont,
//     pw.Font regularFont,
//   ) {
//     final hasCredit = data.previousBalance < 0;
//     final dueIsCredit = data.totalDue < 0;

//     final columns = <MapEntry<String, String>>[
//       if (data.hasDiscount)
//         MapEntry('الخصم', _formatAmount(data.discountAmount)),
//       MapEntry('إجمالي الفاتورة', _formatAmount(data.invoiceTotal)),
//       MapEntry(
//         hasCredit ? 'رصيد العميل السابق (دائن)' : 'الحساب السابق',
//         _formatAmount(data.previousBalance.abs()),
//       ),
//       MapEntry(
//         dueIsCredit ? 'رصيد العميل بعد الفاتورة (دائن)' : 'إجمالي الحساب',
//         _formatAmount(data.totalDue.abs()),
//       ),
//       MapEntry('المبلغ المدفوع', _formatAmount(data.paidNow)),
//       MapEntry('المبلغ المتبقي', _formatAmount(data.remaining)),
//     ].reversed.toList();

//     final headers = columns.map((c) => c.key).toList();
//     final values = columns.map((c) => '${c.value} ج.م').toList();

//     return _buildStyledTable(
//         'ملخص الفاتورة', headers, [values], boldFont, regularFont);
//   }

//   static pw.Widget _buildOldDebtTable(
//     InvoicePdfData data,
//     pw.Font boldFont,
//     pw.Font regularFont,
//   ) {
//     final headers = ['المبلغ', 'الفاتورة القديمة', 'م'];
//     final rows = <List<String>>[
//       for (var i = 0; i < data.oldDebtCollected.length; i++)
//         [
//           '${_formatAmount(data.oldDebtCollected[i].amount)} ج.م',
//           data.oldDebtCollected[i].invoiceCode,
//           '${i + 1}',
//         ],
//     ];

//     return _buildStyledTable(
//       'دين قديم اتحصّل مع الفاتورة دي',
//       headers,
//       rows,
//       boldFont,
//       regularFont,
//       columnWidths: const {
//         0: pw.FlexColumnWidth(1.4),
//         1: pw.FlexColumnWidth(2.6),
//         2: pw.FlexColumnWidth(0.6),
//       },
//     );
//   }

//   static pw.Widget _buildStyledTable(
//     String? title,
//     List<String> headers,
//     List<List<String>> rows,
//     pw.Font boldFont,
//     pw.Font regularFont, {
//     Map<int, pw.TableColumnWidth>? columnWidths,
//   }) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         if (title != null) ...[
//           pw.Text(
//             title,
//             style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green),
//           ),
//           pw.SizedBox(height: 8),
//         ],
//         pw.Table(
//           border: pw.TableBorder.all(color: _border, width: 0.6),
//           columnWidths: columnWidths,
//           children: [
//             pw.TableRow(
//               decoration: pw.BoxDecoration(color: _navy),
//               children: headers
//                   .map(
//                     (h) => pw.Padding(
//                       padding: const pw.EdgeInsets.symmetric(
//                           vertical: 6, horizontal: 4),
//                       child: pw.Text(
//                         h,
//                         textAlign: pw.TextAlign.center,
//                         style: pw.TextStyle(
//                           font: boldFont,
//                           fontSize: 9.5,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ),
//                   )
//                   .toList(),
//             ),
//             for (final row in rows)
//               pw.TableRow(
//                 children: row
//                     .map(
//                       (cell) => pw.Padding(
//                         padding: const pw.EdgeInsets.symmetric(
//                             vertical: 6, horizontal: 4),
//                         child: pw.Text(
//                           cell,
//                           textAlign: pw.TextAlign.center,
//                           style: pw.TextStyle(font: regularFont, fontSize: 10),
//                         ),
//                       ),
//                     )
//                     .toList(),
//               ),
//           ],
//         ),
//       ],
//     );
//   }

//   static String _formatAmount(double value) {
//     final whole = value.abs().truncate();
//     final digits = whole.toString();
//     final buffer = StringBuffer();
//     for (int i = 0; i < digits.length; i++) {
//       if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
//       buffer.write(digits[i]);
//     }
//     var out = (value < 0 ? '-' : '') + buffer.toString();
//     final decimals = (value.abs() - whole);
//     if (decimals > 0.005) {
//       out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
//     }
//     return out;
//   }

//   static String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }
// }
import 'dart:math' as math;
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

  double get totalAfterDiscount => invoiceTotal;

  double get discountPercent => subtotalBeforeDiscount > 0
      ? discountAmount / subtotalBeforeDiscount * 100
      : 0;

  double get oldDebtTotal =>
      oldDebtCollected.fold(0.0, (sum, l) => sum + l.amount);
}

class _BookPage {
  final List<InvoicePdfLineItem> items;
  final int startIndex;
  final bool isFirst;
  final bool hasSummary;

  const _BookPage({
    required this.items,
    required this.startIndex,
    required this.isFirst,
    required this.hasSummary,
  });
}

class InvoicePdfBuilder {
  InvoicePdfBuilder._();

  static const int imageSinglePageMaxItems = 12;
  static const int bookFirstPageRows = 18;
  static const int bookOtherPageRows = 24;
  static const double _pageMargin = 28;

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<List<pw.Font>> _loadFonts() async {
    final regularFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    return [pw.Font.ttf(regularFontData), pw.Font.ttf(boldFontData)];
  }

  static Future<Uint8List> build(InvoicePdfData data) async {
    final document = pw.Document();

    final fonts = await _loadFonts();
    final regularFont = fonts[0];
    final boldFont = fonts[1];

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

  static bool fitsSingleImage(InvoicePdfData data) {
    final debtPenalty =
        data.oldDebtCollected.isEmpty ? 0 : data.oldDebtCollected.length + 3;
    return data.items.length <= imageSinglePageMaxItems - debtPenalty;
  }

  static int imagePageCount(InvoicePdfData data) {
    if (fitsSingleImage(data)) return 1;
    return _paginateBook(data).length;
  }

  static Future<Uint8List> buildImageSource(InvoicePdfData data) async {
    final document = pw.Document();

    final fonts = await _loadFonts();
    final regularFont = fonts[0];
    final boldFont = fonts[1];

    if (fitsSingleImage(data)) {
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(_pageMargin),
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            buildBackground: (context) =>
                buildWhitePdfBackground(watermarkBytes: null),
          ),
          build: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildTitle(data, boldFont),
                pw.SizedBox(height: 22),
                _buildMetaRow(data, boldFont),
                pw.SizedBox(height: 18),
                _buildItemsTable(data.items, boldFont, regularFont),
                pw.SizedBox(height: 16),
                _buildSummaryTable(data, boldFont, regularFont),
                if (data.oldDebtCollected.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  _buildOldDebtTable(data, boldFont, regularFont),
                ],
              ],
            ),
          ),
        ),
      );
      return document.save();
    }

    final pages = _paginateBook(data);
    final spreadFormat = PdfPageFormat(
      PdfPageFormat.a4.width * 2,
      PdfPageFormat.a4.height,
    );

    for (var i = 0; i < pages.length; i += 2) {
      final rightPage = pages[i];
      final leftPage = i + 1 < pages.length ? pages[i + 1] : null;

      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: spreadFormat,
            margin: pw.EdgeInsets.zero,
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            buildBackground: (context) =>
                buildWhitePdfBackground(watermarkBytes: null),
          ),
          build: (context) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: leftPage == null
                    ? pw.SizedBox()
                    : _buildBookPage(
                        data,
                        leftPage,
                        i + 2,
                        pages.length,
                        boldFont,
                        regularFont,
                      ),
              ),
              pw.Container(
                width: 1.5,
                height: PdfPageFormat.a4.height,
                color: _border,
              ),
              pw.Expanded(
                child: _buildBookPage(
                  data,
                  rightPage,
                  i + 1,
                  pages.length,
                  boldFont,
                  regularFont,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return document.save();
  }

  static List<_BookPage> _paginateBook(InvoicePdfData data) {
    final summaryCost = 8 +
        (data.oldDebtCollected.isEmpty ? 0 : data.oldDebtCollected.length + 3);
    final pages = <_BookPage>[];
    var index = 0;
    var capacity = bookFirstPageRows;

    while (index < data.items.length) {
      final end = math.min(index + capacity, data.items.length);
      pages.add(
        _BookPage(
          items: data.items.sublist(index, end),
          startIndex: index,
          isFirst: pages.isEmpty,
          hasSummary: false,
        ),
      );
      index = end;
      capacity = bookOtherPageRows;
    }

    if (pages.isEmpty) {
      pages.add(
        const _BookPage(
          items: [],
          startIndex: 0,
          isFirst: true,
          hasSummary: false,
        ),
      );
    }

    final last = pages.last;
    final lastCapacity = last.isFirst ? bookFirstPageRows : bookOtherPageRows;
    if (lastCapacity - last.items.length >= summaryCost) {
      pages[pages.length - 1] = _BookPage(
        items: last.items,
        startIndex: last.startIndex,
        isFirst: last.isFirst,
        hasSummary: true,
      );
    } else {
      pages.add(
        _BookPage(
          items: const [],
          startIndex: data.items.length,
          isFirst: false,
          hasSummary: true,
        ),
      );
    }

    return pages;
  }

  static pw.Widget _buildBookPage(
    InvoicePdfData data,
    _BookPage page,
    int pageNumber,
    int pageCount,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(_pageMargin),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.SizedBox(
          height: PdfPageFormat.a4.height - _pageMargin * 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (page.isFirst) ...[
                _buildTitle(data, boldFont),
                pw.SizedBox(height: 22),
                _buildMetaRow(data, boldFont),
                pw.SizedBox(height: 18),
              ] else ...[
                _buildCompactHeader(data, boldFont),
                pw.SizedBox(height: 14),
              ],
              if (page.items.isNotEmpty)
                _buildItemsTable(
                  page.items,
                  boldFont,
                  regularFont,
                  startIndex: page.startIndex,
                ),
              if (page.hasSummary) ...[
                pw.SizedBox(height: 16),
                _buildSummaryTable(data, boldFont, regularFont),
                if (data.oldDebtCollected.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  _buildOldDebtTable(data, boldFont, regularFont),
                ],
              ],
              pw.Spacer(),
              pw.Divider(color: _green, thickness: 1),
              pw.Center(
                child: pw.Text(
                  'صفحة $pageNumber من $pageCount',
                  style: pw.TextStyle(font: regularFont, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildCompactHeader(InvoicePdfData data, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'فاتورة مبيعات',
          style: pw.TextStyle(font: boldFont, fontSize: 14, color: _navy),
        ),
        pw.Text(
          'No. ${data.invoiceNumber}',
          style: pw.TextStyle(font: boldFont, fontSize: 10, color: _green),
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
    pw.Font regularFont, {
    int startIndex = 0,
  }) {
    final headers = ['الإجمالي', 'السعر', 'العدد', 'الصنف / المنتج', 'م'];

    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add([
        item.total.toStringAsFixed(0),
        item.price.toStringAsFixed(0),
        '${item.quantity}',
        item.name,
        '${startIndex + i + 1}',
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
    var offset = 0;
    for (var index = 0; index < chunks.length; index++) {
      if (index > 0) widgets.add(pw.NewPage());
      widgets.add(
        _buildItemsTable(
          chunks[index],
          boldFont,
          regularFont,
          startIndex: offset,
        ),
      );
      offset += chunks[index].length;
    }
    return widgets;
  }

  static pw.Widget _buildSummaryTable(
    InvoicePdfData data,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final hasCredit = data.previousBalance < 0;
    final dueIsCredit = data.totalDue < 0;

    final columns = <MapEntry<String, String>>[
      MapEntry('إجمالي الفاتورة', _formatAmount(data.invoiceTotal)),
      MapEntry(
        hasCredit ? 'رصيد العميل السابق (دائن)' : 'الحساب السابق',
        _formatAmount(data.previousBalance.abs()),
      ),
      MapEntry(
        dueIsCredit ? 'رصيد العميل بعد الفاتورة (دائن)' : 'إجمالي الحساب',
        _formatAmount(data.totalDue.abs()),
      ),
      MapEntry('المبلغ المدفوع', _formatAmount(data.paidNow)),
      if (data.hasDiscount)
        MapEntry('الخصم', _formatAmount(data.discountAmount)),
      MapEntry('المبلغ المتبقي', _formatAmount(data.remaining)),
    ].reversed.toList();

    final headers = columns.map((c) => c.key).toList();
    final values = columns.map((c) => '${c.value} ج.م').toList();

    return _buildStyledTable(
        'ملخص الفاتورة', headers, [values], boldFont, regularFont);
  }

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