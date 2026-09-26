import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/app_text_styles.dart';
import '../../../inventory/domain/models/delivery_vehicle_model.dart';
import '../../../inventory/domain/models/product_catalog.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';
import '../../../inventory/domain/models/vehicle_stock_added_today_model.dart';
import 'package:mivet_app/core/utils/pdf_page_background.dart';
import 'report/all_stock_report_sections.dart';
import 'report/report_layout_widgets.dart';
import 'report/report_paginator.dart';
import 'report/report_section.dart';
import 'report/report_table_widget.dart';
import 'report/today_stock_report_sections.dart';

class VehicleStockReportBuilder {
  VehicleStockReportBuilder._();

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
      sectionsBuilder: () => buildAllStockReportSections(stock, catalog),
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
      sectionsBuilder: () => buildAllStockReportSections(stock, catalog),
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
      sectionsBuilder: () => buildTodayStockReportSections(stock, catalog),
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
      sectionsBuilder: () => buildTodayStockReportSections(stock, catalog),
      singlePage: true,
    );
    return document.save();
  }

  static Future<pw.Document> _buildDocument({
    required String representativeName,
    required DeliveryVehicleModel vehicle,
    required String title,
    required List<ReportSection> Function() sectionsBuilder,
    required bool singlePage,
  }) async {
    final document = pw.Document();

    final regularFontData = await rootBundle.load(
        'assets/fonts/${AppTextStyles.cairoRegular14.fontFamily}-Regular.ttf');
    final boldFontData = await rootBundle
        .load('assets/fonts/${AppTextStyles.cairoBold18.fontFamily}-Bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    pw.Widget buildBackground(pw.Context context) => buildWhitePdfBackground();

    final sections = sectionsBuilder();

    if (singlePage) {
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            textDirection: pw.TextDirection.rtl,
            buildBackground: buildBackground,
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildReportTitle(title, boldFont),
              pw.SizedBox(height: 18),
              buildReportMetaRow(representativeName, vehicle, boldFont),
              pw.SizedBox(height: 20),
              for (final section in sections) ...[
                buildReportSectionTable(section, boldFont, regularFont),
                pw.SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );
      return document;
    }

    final pages = paginateReportSections(sections);
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageSections = pages[pageIndex];
      final isFirstPage = pageIndex == 0;
      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            textDirection: pw.TextDirection.rtl,
            buildBackground: buildBackground,
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.max,
            children: [
              if (isFirstPage) ...[
                buildReportTitle(title, boldFont),
                pw.SizedBox(height: 18),
                buildReportMetaRow(representativeName, vehicle, boldFont),
                pw.SizedBox(height: 20),
              ],
              for (final section in pageSections) ...[
                buildReportSectionTable(section, boldFont, regularFont),
                pw.SizedBox(height: 16),
              ],
              pw.Spacer(),
              buildReportPageFooter(pageIndex, pages.length, regularFont),
            ],
          ),
        ),
      );
    }

    return document;
  }
}
