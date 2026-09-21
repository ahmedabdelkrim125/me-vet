import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 11.sp)),
          SizedBox(width: 8.w),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 11.sp),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
