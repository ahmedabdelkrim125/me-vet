import 'package:pdf/widgets.dart' as pw;
import '../../../../inventory/domain/models/product_catalog.dart';
import '../../../../inventory/domain/models/vehicle_stock_model.dart';
import 'report_section.dart';
import 'report_text_utils.dart';

List<ReportSection> buildAllStockReportSections(
  List<VehicleStockModel> stock,
  ProductCatalog catalog,
) {
  final grouped = groupStockByCategory(stock, catalog);
  final sections = <ReportSection>[];
  for (final entry in grouped.entries) {
    sections.add(buildStockReportSection(entry.key, entry.value));
  }
  return sections;
}

Map<String, List<VehicleStockModel>> groupStockByCategory(
  List<VehicleStockModel> stock,
  ProductCatalog catalog,
) {
  final grouped = <String, List<VehicleStockModel>>{};
  for (final item in stock) {
    final product = item.product;
    if (product == null) continue;
    final categoryName =
        sanitizeReportText(catalog.categoryName(product.category));
    grouped.putIfAbsent(categoryName, () => []).add(item);
  }
  return grouped;
}

ReportSection buildStockReportSection(
  String categoryName,
  List<VehicleStockModel> items,
) {
  final headers = ['الكمية', 'اسم الصنف', 'م'];
  final rows = <List<String>>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    rows.add([
      '${item.quantity}',
      sanitizeReportText(item.product!.name),
      '${i + 1}',
    ]);
  }
  return ReportSection(categoryName, headers, rows, const {
    0: pw.FlexColumnWidth(1.4),
    1: pw.FlexColumnWidth(4),
    2: pw.FlexColumnWidth(0.7),
  });
}
