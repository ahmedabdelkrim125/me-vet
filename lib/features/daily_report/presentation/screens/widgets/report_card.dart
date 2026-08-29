import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String label, String value)> rows;

  const ReportCard({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: colors.primary),
              SizedBox(width: 8.w),
              Text(title,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 10.h),
          for (final row in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Text(row.$1,
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 11.sp)),
                  const Spacer(),
                  Text(row.$2,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.text, fontSize: 12.sp)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String moneyLabel(double v) => '${v.toStringAsFixed(0)} ج.م';
