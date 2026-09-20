import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/const/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../inventory/domain/models/delivery_vehicle_model.dart';
import '../../../inventory/domain/models/product_catalog.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';
import '../../../inventory/domain/models/vehicle_stock_added_today_model.dart';

class VehicleStockReportBuilder {
  VehicleStockReportBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);
  static const _companyContactNumber = '01091192831';

  static Future<Uint8List> buildPdf({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockModel> stock,
    required ProductCatalog catalog,
  }) async {
    final document = await _buildDocument(
      representativeName: representativeName,
      vehicle: vehicle,
      title: 'تقرير مخزون العربية',
      tableBuilder: (boldFont, regularFont) =>
          _buildAllStockTables(stock, catalog, boldFont, regularFont),
      singlePage: false,
    );
    return document.save();
  }

  static Future<Uint8List> buildImageSource({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockModel> stock,
    required ProductCatalog catalog,
  }) async {
    final document = await _buildDocument(
      representativeName: representativeName,
      vehicle: vehicle,
      title: 'تقرير مخزون العربية',
      tableBuilder: (boldFont, regularFont) =>
          _buildAllStockTables(stock, catalog, boldFont, regularFont),
      singlePage: true,
    );
    return document.save();
  }

  static Future<Uint8List> buildTodayPdf({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockAddedTodayModel> stock,
    required ProductCatalog catalog,
  }) async {
    final document = await _buildDocument(
      representativeName: representativeName,
      vehicle: vehicle,
      title: 'تقرير الإضافة اليومي',
      tableBuilder: (boldFont, regularFont) =>
          _buildTodayStockTables(stock, catalog, boldFont, regularFont),
      singlePage: false,
    );
    return document.save();
  }

  static Future<Uint8List> buildTodayImageSource({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockAddedTodayModel> stock,
    required ProductCatalog catalog,
  }) async {
    final document = await _buildDocument(
      representativeName: representativeName,
      vehicle: vehicle,
      title: 'تقرير الإضافة اليومي',
      tableBuilder: (boldFont, regularFont) =>
          _buildTodayStockTables(stock, catalog, boldFont, regularFont),
      singlePage: true,
    );
    return document.save();
  }

  static Future<pw.Document> _buildDocument({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required String title,
    required List<pw.Widget> Function(pw.Font, pw.Font) tableBuilder,
    required bool singlePage,
  }) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
        'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf');
    final boldFontData = await rootBundle
        .load('assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf');
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

    final content = pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildTitle(title, boldFont),
          pw.SizedBox(height: 18),
          _buildMetaRow(representativeName, vehicle, boldFont),
          pw.SizedBox(height: 20),
          ...tableBuilder(boldFont, regularFont),
        ],
      ),
    );

    pw.Widget buildBackground(pw.Context context) {
      if (watermarkBytes == null) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 35),
        child: pw.Center(
          child: pw.Image(pw.MemoryImage(watermarkBytes), width: 320),
        ),
      );
    }

    if (singlePage) {
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            buildBackground: buildBackground,
          ),
          build: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(logoBytes, boldFont),
                pw.SizedBox(height: 18),
                content,
              ],
            ),
          ),
        ),
      );
    } else {
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            buildBackground: buildBackground,
          ),
          header: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: _buildHeader(logoBytes, boldFont),
          ),
          footer: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: _buildFooter(boldFont),
          ),
          build: (context) => [content],
        ),
      );
    }

    return document;
  }

  static List<pw.Widget> _buildAllStockTables(
    List<VehicleStockModel> stock,
    ProductCatalog catalog,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final grouped = _groupByCategory(stock, catalog);
    final widgets = <pw.Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        _buildCategoryTable(entry.key, entry.value, boldFont, regularFont),
      );
      widgets.add(pw.SizedBox(height: 16));
    }
    return widgets;
  }

  static List<pw.Widget> _buildTodayStockTables(
    List<VehicleStockAddedTodayModel> stock,
    ProductCatalog catalog,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final grouped = <String, List<VehicleStockAddedTodayModel>>{};
    for (final item in stock) {
      final categoryName = catalog.categoryName(item.category);
      grouped.putIfAbsent(categoryName, () => []).add(item);
    }
    final widgets = <pw.Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        _buildTodayCategoryTable(entry.key, entry.value, boldFont, regularFont),
      );
      widgets.add(pw.SizedBox(height: 16));
    }
    return widgets;
  }

  static Map<String, List<VehicleStockModel>> _groupByCategory(
    List<VehicleStockModel> stock,
    ProductCatalog catalog,
  ) {
    final grouped = <String, List<VehicleStockModel>>{};
    for (final item in stock) {
      final product = item.product;
      if (product == null) continue;
      final categoryName = catalog.categoryName(product.category);
      grouped.putIfAbsent(categoryName, () => []).add(item);
    }
    return grouped;
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
            pw.Text(_companyContactNumber,
                style: _valueStyle(boldFont, _green)),
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

  static pw.Widget _buildTitle(String title, pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy),
      ),
    );
  }

  static pw.Widget _buildMetaRow(
    String representativeName,
    DeliveryVehicleModel vehicle,
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('اسم المندوب : $representativeName',
                style: pw.TextStyle(font: boldFont, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text('رقم العربية : ${vehicle.plateNumber}',
                style: pw.TextStyle(font: boldFont, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text('السائق : ${vehicle.driverName}',
                style: pw.TextStyle(font: boldFont, fontSize: 11)),
          ],
        ),
        pw.Text(
          'تاريخ التقرير : ${_formatDate(DateTime.now())}',
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

  static pw.Widget _buildCategoryTable(
    String categoryName,
    List<VehicleStockModel> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = ['حالة المخزون', 'الحد الأدنى', 'الكمية', 'اسم الصنف', 'م'];
    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add([
        _stockStatusLabel(item),
        '${item.minThreshold}',
        '${item.quantity}',
        item.product!.name,
        '${i + 1}',
      ]);
    }
    return _buildTableWrapper(
        categoryName, headers, rows, boldFont, regularFont, const {
      0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(1.4),
      2: pw.FlexColumnWidth(1.4),
      3: pw.FlexColumnWidth(3),
      4: pw.FlexColumnWidth(0.6),
    });
  }

  static pw.Widget _buildTodayCategoryTable(
    String categoryName,
    List<VehicleStockAddedTodayModel> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final headers = [
      'الكمية الحالية',
      'وقت الإضافة',
      'الكمية المضافة',
      'اسم الصنف',
      'م'
    ];
    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final timeFormatted =
          '${item.addedAt.hour.toString().padLeft(2, '0')}:${item.addedAt.minute.toString().padLeft(2, '0')}';
      rows.add([
        '${item.currentQuantity}',
        timeFormatted,
        '${item.quantityAdded}',
        item.productName,
        '${i + 1}',
      ]);
    }
    return _buildTableWrapper(
        categoryName, headers, rows, boldFont, regularFont, const {
      0: pw.FlexColumnWidth(1.4),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.4),
      3: pw.FlexColumnWidth(3),
      4: pw.FlexColumnWidth(0.6),
    });
  }

  static pw.Widget _buildTableWrapper(
    String title,
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font regularFont,
    Map<int, pw.TableColumnWidth> columnWidths,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: _green)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.6),
          columnWidths: columnWidths,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _navy),
              children: headers
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        child: pw.Text(
                          h,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: PdfColors.white),
                        ),
                      ))
                  .toList(),
            ),
            for (final row in rows)
              pw.TableRow(
                children: row
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          child: pw.Text(
                            cell,
                            textAlign: pw.TextAlign.center,
                            style:
                                pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ],
    );
  }

  static String _stockStatusLabel(VehicleStockModel stock) {
    if (stock.quantity == 0) return 'نفذ من المخزون';
    if (stock.isLowStock) return 'منخفض';
    return 'متوفر';
  }

  static pw.TextStyle _labelStyle(pw.Font boldFont) =>
      pw.TextStyle(font: boldFont, fontSize: 10, color: _navy);
  static pw.TextStyle _valueStyle(pw.Font boldFont, PdfColor color) =>
      pw.TextStyle(font: boldFont, fontSize: 10, color: color);
  static String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
