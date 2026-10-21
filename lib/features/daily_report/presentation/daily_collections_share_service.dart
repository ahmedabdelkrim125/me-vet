import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/invoice_share_service.dart'
    show ShareFormatOption;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/daily_collections_pdf_builder.dart';
import '../domain/daily_collections_repository.dart';

enum DailyCollectionsShareFormat { image, pdf }

class DailyCollectionsShareService {
  DailyCollectionsShareService._();

  static const int imageMaxItems = 20;
  static const double imageDpi = 200;

  static bool fitsSingleImage(List<DailyCollectionSummary> collections) =>
      collections.length <= imageMaxItems;

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _fileBase(DateTime day, String? customerName) {
    final date = '${day.year}-${_two(day.month)}-${_two(day.day)}';
    return customerName == null
        ? 'daily_collections_$date'
        : 'customer_collections_$date';
  }

  static Future<void> askAndShare(
    BuildContext context,
    List<DailyCollectionSummary> collections,
    DateTime day, {
    String? customerName,
  }) async {
    if (collections.isEmpty) return;

    final format = await _askFormat(context, collections, customerName);
    if (format == null || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final base = _fileBase(day, customerName);

    try {
      final bytes = await DailyCollectionsPdfBuilder.build(
        collections,
        day,
        customerName: customerName,
      );

      if (format == DailyCollectionsShareFormat.pdf) {
        navigator.pop();
        await PdfExport.share(bytes, '$base.pdf');
      } else {
        final files = await _buildImageFiles(bytes, base);
        navigator.pop();
        await SharePlus.instance.share(
          ShareParams(
            files: files,
            text: customerName == null
                ? 'التحصيلات اليومية'
                : 'تحصيلات $customerName',
          ),
        );
      }
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (context.mounted) showAppError(context, e);
    }
  }

  static Future<List<XFile>> _buildImageFiles(
    Uint8List source,
    String base,
  ) async {
    final files = <XFile>[];
    var index = 1;

    await for (final raster in Printing.raster(source, dpi: imageDpi)) {
      final png = await raster.toPng();
      files.add(
        XFile.fromData(
          png,
          mimeType: 'image/png',
          name: '${base}_$index.png',
        ),
      );
      index++;
    }

    if (files.isEmpty) {
      throw StateError('تعذر إنشاء صورة التحصيلات، جرّب تاني');
    }
    return files;
  }

  static Future<DailyCollectionsShareFormat?> _askFormat(
    BuildContext context,
    List<DailyCollectionSummary> collections,
    String? customerName,
  ) {
    final isLarge = !fitsSingleImage(collections);
    final imageSubtitle = isLarge
        ? 'التحصيلات كتير، الصورة هتتقسم لعدة صفحات'
        : 'صورة واحدة تتفتح على أي موبايل';
    final pdfSubtitle =
        isLarge ? 'الأنسب للتحصيلات الكتيرة' : 'ملف PDF يحتاج برنامج لفتحه';
    final title = customerName == null
        ? 'مشاركة التحصيلات كـ'
        : 'مشاركة تحصيلات $customerName كـ';

    return showModalBottomSheet<DailyCollectionsShareFormat>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        return SafeArea(
          child: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: colors.text,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                ShareFormatOption(
                  icon: Icons.image_outlined,
                  title: 'صورة',
                  subtitle: imageSubtitle,
                  recommended: !isLarge,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    DailyCollectionsShareFormat.image,
                  ),
                ),
                SizedBox(height: 10.h),
                ShareFormatOption(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF',
                  subtitle: pdfSubtitle,
                  recommended: isLarge,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    DailyCollectionsShareFormat.pdf,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
