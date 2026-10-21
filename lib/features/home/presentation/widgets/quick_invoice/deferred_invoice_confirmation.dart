import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';

Future<bool> showFullyDeferredInvoiceConfirmation(
  BuildContext context,
  QuickInvoiceState state,
) async {
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: colors.statOrange, size: 22.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'فاتورة آجلة بدون تحصيل',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.text, fontSize: 15.sp),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'العميل لم يدفع أي مبلغ (المدفوع الآن = 0).',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.text, fontSize: 12.5.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            state.previousBalance < 0
                ? 'سيتم خصم ${formatMoney(state.creditUsed)} من رصيد العميل الدائن، وإضافة ${formatMoney(state.totalDue)} إلى رصيده المستحق.'
                : 'سيتم تسجيل الفاتورة كفاتورة آجلة بالكامل، وإضافة مبلغ ${formatMoney(state.totalDue)} بالكامل إلى رصيد العميل المستحق.',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.statOrange, fontSize: 12.sp),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'رجوع',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.textMuted, fontSize: 13.sp),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'تأكيد وإصدار الفاتورة',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: Colors.white, fontSize: 13.sp),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
