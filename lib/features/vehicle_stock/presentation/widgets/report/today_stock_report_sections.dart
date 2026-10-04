import 'package:pdf/widgets.dart' as pw;
import '../../../../inventory/domain/models/product_catalog.dart';
import '../../../../inventory/domain/models/vehicle_stock_added_today_model.dart';
import 'report_section.dart';
import 'report_text_utils.dart';

List<ReportSection> buildTodayStockReportSections(
  List<VehicleStockAddedTodayModel> stock,
  ProductCatalog catalog,
) {
  if (stock.isEmpty) return <ReportSection>[];
  final sorted = [...stock]..sort((a, b) => a.addedAt.compareTo(b.addedAt));
  return [buildTodayStockReportSection('', sorted)];
}

ReportSection buildTodayStockReportSection(
  String title,
  List<VehicleStockAddedTodayModel> items,
) {
  final headers = [
    'الكمية الحالية',
    'الكمية المضافة',
    'اسم الصنف',
    'م',
  ];
  final rows = <List<String>>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    rows.add([
      '${item.currentQuantity}',
      '${item.quantityAdded}',
      sanitizeReportText(item.productName),
      '${i + 1}',
    ]);
  }
  return ReportSection(title, headers, rows, const {
    0: pw.FlexColumnWidth(1.4),
    1: pw.FlexColumnWidth(1.4),
    2: pw.FlexColumnWidth(3.6),
    3: pw.FlexColumnWidth(0.7),
  });
}

String? todayReportTimeRangeLabel(List<VehicleStockAddedTodayModel> stock) {
  if (stock.isEmpty) return null;
  var first = stock.first.addedAt;
  var last = first;
  for (final item in stock) {
    if (item.addedAt.isBefore(first)) first = item.addedAt;
    if (item.addedAt.isAfter(last)) last = item.addedAt;
  }
  final from = formatReportTime12(first);
  final to = formatReportTime12(last);
  if (from == to) return 'وقت الإضافة : $from';
  return 'وقت الإضافة : من $from إلى $to';
}
