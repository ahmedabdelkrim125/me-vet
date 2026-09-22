import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../inventory/domain/models/delivery_vehicle_model.dart';
import '../../../inventory/domain/models/product_catalog.dart';
import '../../../inventory/domain/models/vehicle_stock_added_today_model.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';
import 'vehicle_stock_report_builder.dart';

class VehicleStockShareService {
  VehicleStockShareService._();

  static const int imageReportProductThreshold = 12;
  static const double imageReportDpi = 200;

  static Future<void> shareVehicleStockReport({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required List<VehicleStockModel> stock,
    required ProductCatalog catalog,
  }) async {
    final reportableStock =
        stock.where((item) => item.product != null).toList();
    final fileNameBase =
        'vehicle_stock_${vehicle.plateNumber.replaceAll(' ', '_')}';

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
        'today_stock_${vehicle.plateNumber.replaceAll(' ', '_')}';

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

  /// Opens the OS share sheet directly for the given PDF bytes. This is the
  /// only step that runs when the person taps "Share" — no print/save
  /// dialog is opened first.
  static Future<void> sharePdfBytes(
    Uint8List pdfBytes,
    String fileNameBase,
  ) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$fileNameBase.pdf',
    );
  }

  /// Separate, optional "Save" action: opens the native print/preview
  /// dialog, which exposes a real "Save as PDF" / "Save to Files"
  /// destination on both iOS and Android. Not called by the share flow —
  /// wire this to its own "Save PDF" control if/when one is added to the
  /// UI.
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
