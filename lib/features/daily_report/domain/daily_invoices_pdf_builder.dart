import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';

class DailyInvoicePdfEntry {
  final String invoiceCode;
  final String customerName;
  final DateTime date;
  final List<({String name, int quantity, double price, double total})> items;
  final double total;
  final String status;
  final InvoicePdfData summary;

  const DailyInvoicePdfEntry({
    required this.invoiceCode,
    required this.customerName,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    required this.summary,
  });
}

class _RenderArgs {
  final List<DailyInvoicePdfEntry> entries;
  final DateTime reportDate;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final int part;
  final int parts;
  final int dayCount;
  final double dayTotal;

  const _RenderArgs({
    required this.entries,
    required this.reportDate,
    required this.regularFont,
    required this.boldFont,
    required this.part,
    required this.parts,
    required this.dayCount,
    required this.dayTotal,
  });
}

Future<Uint8List> _renderPart(_RenderArgs args) {
  return DailyInvoicesPdfBuilder._render(args);
}

class DailyInvoicesPdfBuilder {
  DailyInvoicesPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static const double _minSpaceToStartInvoice = 130;

  static Future<List<Uint8List>> buildParts(
    List<DailyInvoicePdfEntry> entries,
    DateTime reportDate, {
    int maxInvoicesPerPart = 20,
    int maxRowsPerPart = 250,
    void Function(int done, int total)? onProgress,
  }) async {
    final regular = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final bold = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    final regularBytes = regular.buffer
        .asUint8List(regular.offsetInBytes, regular.lengthInBytes);
    final boldBytes =
        bold.buffer.asUint8List(bold.offsetInBytes, bold.lengthInBytes);

    final groups = _partition(entries, maxInvoicesPerPart, maxRowsPerPart);
    final dayTotal = entries.fold(0.0, (sum, e) => sum + e.total);
    final results = <Uint8List>[];

    for (var i = 0; i < groups.length; i++) {
      final pdfs = await _renderResilient(
        groups[i],
        reportDate,
        regularBytes,
        boldBytes,
        i + 1,
        groups.length,
        entries.length,
        dayTotal,
      );
      results.addAll(pdfs);
      onProgress?.call(i + 1, groups.length);
    }
    return results;
  }

  static List<List<DailyInvoicePdfEntry>> _partition(
    List<DailyInvoicePdfEntry> entries,
    int maxInvoices,
    int maxRows,
  ) {
    final groups = <List<DailyInvoicePdfEntry>>[];
    var current = <DailyInvoicePdfEntry>[];
    var rows = 0;
    for (final entry in entries) {
      final entryRows = entry.items.length + 6;
      final full = current.length >= maxInvoices ||
          (current.isNotEmpty && rows + entryRows > maxRows);
      if (full) {
        groups.add(current);
        current = <DailyInvoicePdfEntry>[];
        rows = 0;
      }
      current.add(entry);
      rows += entryRows;
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  static Future<List<Uint8List>> _renderResilient(
    List<DailyInvoicePdfEntry> group,
    DateTime reportDate,
    Uint8List regularBytes,
    Uint8List boldBytes,
    int part,
    int parts,
    int dayCount,
    double dayTotal,
  ) async {
    try {
      final args = _RenderArgs(
        entries: group,
        reportDate: reportDate,
        regularFont: regularBytes,
        boldFont: boldBytes,
        part: part,
        parts: parts,
        dayCount: dayCount,
        dayTotal: dayTotal,
      );
      final bytes = await Isolate.run(() => _renderPart(args));
      return [bytes];
    } catch (error) {
      if (group.length <= 1) {
        final code = group.isEmpty ? '' : group.first.invoiceCode;
        throw StateError('تعذر إنشاء ملف الفاتورة $code: $error');
      }
      final middle = group.length ~/ 2;
      final first = await _renderResilient(
        group.sublist(0, middle),
        reportDate,
        regularBytes,
        boldBytes,
        part,
        parts,
        dayCount,
        dayTotal,
      );
      final second = await _renderResilient(
        group.sublist(middle),
        reportDate,
        regularBytes,
        boldBytes,
        part,
        parts,
        dayCount,
        dayTotal,
      );
      return [...first, ...second];
    }
  }

  static Future<Uint8List> _render(_RenderArgs args) async {
    final document = pw.Document();
    final regularFont = pw.Font.ttf(ByteData.sublistView(args.regularFont));
    final boldFont = pw.Font.ttf(ByteData.sublistView(args.boldFont));

    final partTotal = args.entries.fold(0.0, (sum, e) => sum + e.total);
    final partLabel =
        args.parts > 1 ? '  (جزء ${args.part} من ${args.parts})' : '';

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
                  'الفواتير اليومية$partLabel',
                  style:
                      pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _formatDate(args.reportDate),
                  style:
                      pw.TextStyle(font: boldFont, fontSize: 11, color: _green),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildTable(
            null,
            args.parts > 1
                ? [
                    'عدد الفواتير',
                    'إجمالي اليوم',
                    'فواتير الجزء',
                    'إجمالي الجزء'
                  ]
                : ['عدد الفواتير', 'إجمالي اليوم'],
            [
              args.parts > 1
                  ? [
                      '${args.dayCount}',
                      '${_formatAmount(args.dayTotal)} ج.م',
                      '${args.entries.length}',
                      '${_formatAmount(partTotal)} ج.م',
                    ]
                  : [
                      '${args.dayCount}',
                      '${_formatAmount(args.dayTotal)} ج.م',
                    ],
            ],
            boldFont,
            regularFont,
          ),
          pw.SizedBox(height: 18),
          for (final entry in args.entries)
            ..._buildInvoiceSection(entry, boldFont, regularFont),
        ],
      ),
    );

    return document.save();
  }

  static List<pw.Widget> _buildInvoiceSection(
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

    return [
      pw.NewPage(freeSpace: _minSpaceToStartInvoice),
      pw.Column(
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
        ],
      ),
      _buildTable(null, headers, rows, boldFont, regularFont),
      pw.SizedBox(height: 12),
      InvoicePdfBuilder.buildSummarySection(
        entry.summary,
        boldFont,
        regularFont,
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: _border, thickness: 0.6),
      pw.SizedBox(height: 14),
    ];
  }

  static pw.Widget _buildTable(
    String? title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final table = pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      children: [
        pw.TableRow(
          repeat: true,
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
                          style: pw.TextStyle(font: regularFont, fontSize: 9)),
                    ))
                .toList(),
          ),
      ],
    );

    if (title == null) return table;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green)),
        pw.SizedBox(height: 8),
        table,
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
