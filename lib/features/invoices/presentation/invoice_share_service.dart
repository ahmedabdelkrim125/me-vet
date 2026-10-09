import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/invoice_pdf_builder.dart';

enum InvoiceShareFormat { image, pdf }

class InvoiceShareService {
  InvoiceShareService._();

  static const double imageDpi = 200;

  static String _fileBase(String invoiceNumber) {
    var name = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    name = name.replaceAll(RegExp(r'_+'), '_');
    if (name.replaceAll('_', '').isEmpty) name = 'invoice';
    return name;
  }

  static Future<void> askAndShare(
    BuildContext context,
    InvoicePdfData data,
  ) async {
    final format = await _askFormat(context, data);
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

    try {
      if (format == InvoiceShareFormat.pdf) {
        final bytes = await InvoicePdfBuilder.build(data);
        navigator.pop();
        await PdfExport.share(bytes, '${_fileBase(data.invoiceNumber)}.pdf');
      } else {
        final files = await _buildImageFiles(data);
        navigator.pop();
        await SharePlus.instance.share(
          ShareParams(
            files: files,
            text: 'فاتورة ${data.invoiceNumber}',
          ),
        );
      }
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (context.mounted) showAppError(context, e);
    }
  }

  static Future<List<XFile>> _buildImageFiles(InvoicePdfData data) async {
    final source = await InvoicePdfBuilder.buildImageSource(data);
    final base = _fileBase(data.invoiceNumber);
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
      throw StateError('تعذر إنشاء صورة الفاتورة، جرّب تاني');
    }
    return files;
  }

  static Future<InvoiceShareFormat?> _askFormat(
    BuildContext context,
    InvoicePdfData data,
  ) {
    final pages = InvoicePdfBuilder.imagePageCount(data);
    final isLarge = !InvoicePdfBuilder.fitsSingleImage(data);
    final imageSubtitle = isLarge
        ? 'الفاتورة كبيرة، هتتقسم لصفحات متجاورة زي الكتاب المفتوح'
        : 'صورة واحدة تتفتح على أي موبايل';
    final pdfSubtitle =
        isLarge ? 'الأنسب للفواتير الكبيرة' : 'ملف PDF يحتاج برنامج لفتحه';

    return showModalBottomSheet<InvoiceShareFormat>(
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
                  'مشاركة الفاتورة كـ',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: colors.text,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                _FormatOption(
                  icon: Icons.image_outlined,
                  title: pages > 1 ? 'صورة ($pages صفحات)' : 'صورة',
                  subtitle: imageSubtitle,
                  recommended: !isLarge,
                  onTap: () =>
                      Navigator.pop(sheetContext, InvoiceShareFormat.image),
                ),
                SizedBox(height: 10.h),
                _FormatOption(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF',
                  subtitle: pdfSubtitle,
                  recommended: isLarge,
                  onTap: () =>
                      Navigator.pop(sheetContext, InvoiceShareFormat.pdf),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FormatOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  const _FormatOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: recommended ? colors.primary : colors.border,
            width: recommended ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28.sp, color: colors.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: colors.text,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (recommended) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'مناسب',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.primary,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.almaraiRegular14.copyWith(
                      color: colors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
