import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../inventory/domain/models/delivery_vehicle_model.dart';
import '../../../inventory/domain/models/product_catalog.dart';
import '../../../inventory/domain/models/vehicle_stock_added_today_model.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';
import 'vehicle_stock_report_builder.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';

class VehicleStockShareService {
  VehicleStockShareService._();

  static const int imageReportProductThreshold = 12;
  static const double imageReportDpi = 200;

  static String _plateDigits(String plateNumber) {
    final digits = plateNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 'unknown' : digits;
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  static Future<void> shareVehicleStockReport({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockModel> stock,
    required ProductCatalog catalog,
  }) async {
    final reportableStock =
        stock.where((item) => item.product != null).toList();
    final fileNameBase =
        'VehicleStockReport_${_plateDigits(vehicle.plateNumber)}_${_timestamp()}';

    if (reportableStock.length <= imageReportProductThreshold) {
      final sourceBytes = await VehicleStockReportBuilder.buildImageSource(
        representativeName: representativeName,
        vehicle: vehicle,
        stock: reportableStock,
        catalog: catalog,
      );
      await _shareImageBytes(sourceBytes, fileNameBase, 'تقرير مخزون العربية');
    } else {
      final pdfBytes = await VehicleStockReportBuilder.buildPdf(
        representativeName: representativeName,
        vehicle: vehicle,
        stock: reportableStock,
        catalog: catalog,
      );
      await sharePdfBytes(pdfBytes, fileNameBase);
    }
  }

  static Future<void> shareVehicleStockTodayReport({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockAddedTodayModel> todayStock,
    required ProductCatalog catalog,
  }) async {
    final fileNameBase =
        'VehicleStockAddedToday_${_plateDigits(vehicle.plateNumber)}_${_timestamp()}';

    if (todayStock.length <= imageReportProductThreshold) {
      final sourceBytes = await VehicleStockReportBuilder.buildTodayImageSource(
        representativeName: representativeName,
        vehicle: vehicle,
        stock: todayStock,
        catalog: catalog,
      );
      await _shareImageBytes(sourceBytes, fileNameBase, 'تقرير إضافة اليوم');
    } else {
      final pdfBytes = await VehicleStockReportBuilder.buildTodayPdf(
        representativeName: representativeName,
        vehicle: vehicle,
        stock: todayStock,
        catalog: catalog,
      );
      await sharePdfBytes(pdfBytes, fileNameBase);
    }
  }

  static Future<void> _shareImageBytes(
    Uint8List sourceBytes,
    String fileNameBase,
    String shareText,
  ) async {
    final rasters = await Printing.raster(
      sourceBytes,
      pages: const [0],
      dpi: imageReportDpi,
    ).toList();

    final imageBytes = await rasters.first.toPng();

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: '$fileNameBase.png',
          ),
        ],
        text: shareText,
      ),
    );
  }

  static Future<void> sharePdfBytes(
    Uint8List pdfBytes,
    String fileNameBase,
  ) async {
    await PdfExport.share(pdfBytes, '$fileNameBase.pdf');
  }

  static Future<void> savePdfBytes(
    Uint8List pdfBytes,
    String fileNameBase,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: fileNameBase,
    );
  }
}
