import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'models/report_period_type.dart';
import 'models/representative_report_model.dart';

class ReportPdfBuilder {
  ReportPdfBuilder._();

  static final _navy = PdfColor.fromInt(AppColors.primary.value);
  static final _green = PdfColor.fromInt(AppColors.primaryGreen.value);
  static final _border = PdfColor.fromInt(AppColors.cardBorder.value);

  static Future<Uint8List> build(RepresentativeReportModel report) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf',
    );
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    document.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(report.periodType.label,
                      style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy)),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المندوب: ${report.repName}',
                        style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    pw.Text('العربية: ${report.vehiclePlateNumber}',
                        style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    pw.Text('يوم عمل: ${report.workDayNumber}',
                        style: pw.TextStyle(font: boldFont, fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 18),
                _section('إحصائيات العملاء', [
                  ['${report.clientStats.totalAssignedClients}', 'إجمالي العملاء'],
                  ['${report.clientStats.visitedClients}', 'تمت زيارتهم'],
                  ['${report.clientStats.completedOrSoldClients}', 'مكتملة / بيع'],
                  ['${report.clientStats.noOrderClients}', 'بدون طلب'],
                  ['${report.clientStats.notReachedClients}', 'لم يوصل'],
                ], boldFont, regularFont),
                pw.SizedBox(height: 14),
                _section('التصفية المالية', [
                  ['${report.cashSettlement.totalInvoicesCount}', 'عدد الفواتير'],
                  [_money(report.cashSettlement.totalInvoicesValue), 'قيمة الفواتير'],
                  [_money(report.cashSettlement.cashCollectedOnNewInvoices), 'تحصيل فواتير جديدة'],
                  [_money(report.cashSettlement.cashCollectedOnOldDebt), 'تحصيل مديونية قديمة'],
                  [_money(report.cashSettlement.roadExpenses), 'مصاريف الطريق'],
                  [_money(report.cashSettlement.expectedCashInHand), 'المفروض معاه كاش'],
                  [_money(report.cashSettlement.outstandingCreditOutside), 'باقي فلوس بره'],
                ], boldFont, regularFont),
                pw.SizedBox(height: 14),
                _section('المخزون', [
                  [_money(report.inventorySummary.loadedFromWarehouseValue), 'محمّل من المخزن للعربية'],
                  [_money(report.inventorySummary.soldFromVehicleValue), 'مباع من العربية'],
                  [_money(report.inventorySummary.remainingVehicleStockValue), 'متبقي بالعربية'],
                  [_money(report.inventorySummary.remainingWarehouseStockValue), 'متبقي بالمخزن'],
                  [_money(report.inventorySummary.returnsValue), 'مرتجعات'],
                  [_money(report.inventorySummary.damagedGoodsValue), 'هالك'],
                ], boldFont, regularFont),
                pw.SizedBox(height: 26),
                pw.Divider(color: _green, thickness: 1),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text('MeVet — Representative Daily Report',
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: _green)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _section(
      String title,
      List<List<String>> rows,
      pw.Font boldFont,
      pw.Font regularFont,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 13, color: _green)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.6),
          children: [
            for (final row in rows)
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: pw.Text(row[0],
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: _navy)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: pw.Text(row[1], style: pw.TextStyle(font: regularFont, fontSize: 10)),
                ),
              ]),
          ],
        ),
      ],
    );
  }

  static String _money(double v) => '${v.toStringAsFixed(0)} ج.م';
}