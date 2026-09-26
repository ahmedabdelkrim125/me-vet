import 'package:pdf/widgets.dart' as pw;
import '../../../../inventory/domain/models/product_catalog.dart';
import '../../../../inventory/domain/models/vehicle_stock_added_today_model.dart';
import 'report_section.dart';
import 'report_text_utils.dart';

List<ReportSection> buildTodayStockReportSections(
  List<VehicleStockAddedTodayModel> stock,
  ProductCatalog catalog,
) {
  final grouped = <String, List<VehicleStockAddedTodayModel>>{};
  for (final item in stock) {
    final categoryName =
        sanitizeReportText(catalog.categoryName(item.category));
    grouped.putIfAbsent(categoryName, () => []).add(item);
  }
  final sections = <ReportSection>[];
  for (final entry in grouped.entries) {
    sections.add(buildTodayStockReportSection(entry.key, entry.value));
  }
  return sections;
}

ReportSection buildTodayStockReportSection(
  String categoryName,
  List<VehicleStockAddedTodayModel> items,
) {
  final headers = [
    'الكمية الحالية',
    'وقت الإضافة',
    'الكمية المضافة',
    'اسم الصنف',
    'م',
  ];
  final rows = <List<String>>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    rows.add([
      '${item.currentQuantity}',
      formatReportTime(item.addedAt),
      '${item.quantityAdded}',
      sanitizeReportText(item.productName),
      '${i + 1}',
    ]);
  }
  return ReportSection(categoryName, headers, rows, const {
    0: pw.FlexColumnWidth(1.4),
    1: pw.FlexColumnWidth(1.6),
    2: pw.FlexColumnWidth(1.4),
    3: pw.FlexColumnWidth(3),
    4: pw.FlexColumnWidth(0.6),
  });
}
