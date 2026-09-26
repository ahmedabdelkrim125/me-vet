import 'package:pdf/widgets.dart' as pw;
import '../../../../inventory/domain/models/delivery_vehicle_model.dart';
import 'report_colors.dart';
import 'report_text_utils.dart';

pw.Widget buildReportTitle(String title, pw.Font boldFont) {
  return pw.Center(
    child: pw.Text(
      sanitizeReportText(title),
      style: pw.TextStyle(font: boldFont, fontSize: 20, color: reportNavy),
    ),
  );
}

pw.Widget buildReportMetaRow(
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
          pw.Text('اسم المندوب : ${sanitizeReportText(representativeName)}',
              style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('رقم العربية : ${sanitizeReportText(vehicle.plateNumber)}',
              style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('السائق : ${sanitizeReportText(vehicle.driverName)}',
              style: pw.TextStyle(font: boldFont, fontSize: 11)),
        ],
      ),
      pw.Text(
        'تاريخ التقرير : ${formatReportDate(DateTime.now())}',
        style: pw.TextStyle(font: boldFont, fontSize: 11),
      ),
    ],
  );
}

pw.Widget buildReportPageFooter(
  int pageIndex,
  int pageCount,
  pw.Font regularFont,
) {
  return pw.Center(
    child: pw.Text(
      'صفحة ${pageIndex + 1} من $pageCount',
      style: pw.TextStyle(font: regularFont, fontSize: 9),
    ),
  );
}
