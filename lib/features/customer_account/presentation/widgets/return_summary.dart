import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class ReturnSummary extends StatelessWidget {
  final double total;

  const ReturnSummary({super.key, required this.total});

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
      child: Row(
        children: [
          Text('إجمالي المرتجع',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoBold18.copyWith(color: colors.primary, fontSize: 15.sp)),
        ],
      ),
    );
  }
}