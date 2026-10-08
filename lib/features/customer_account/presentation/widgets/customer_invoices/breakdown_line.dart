import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';

class BreakdownLine extends StatelessWidget {
  final PaymentBreakdownLine line;
  final String amountText;

  const BreakdownLine({super.key, required this.line, required this.amountText});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = line.isOwnInvoice ? 'دفعة الفاتورة' : 'دين قديم';
    final target = line.invoiceCode ?? 'رصيد سابق';
    final accent = line.isOwnInvoice ? colors.primary : colors.statOrange;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              kind,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: accent, fontSize: 9.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              target,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.text, fontSize: 11.sp),
            ),
          ),
          Text(
            '$amountText ج.م',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
