import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class HistoricalTotalsCard extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double total;

  const HistoricalTotalsCard({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
  });

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 15.sp)
                : AppTextStyles.cairoMedium16.copyWith(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _row(context, 'الإجمالي قبل الخصم',
              '${subtotal.toStringAsFixed(0)} ج.م'),
          _row(context, 'الخصم', '${discountAmount.toStringAsFixed(0)} ج.م'),
          const Divider(),
          _row(context, 'الإجمالي النهائي', '${total.toStringAsFixed(0)} ج.م',
              bold: true),
        ],
      ),
    );
  }
}
