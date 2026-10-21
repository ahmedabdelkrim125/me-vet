import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceStaticField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InvoiceStaticField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(icon, size: 15.sp, color: colors.text),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
