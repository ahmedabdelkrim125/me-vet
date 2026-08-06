import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteActionsBar extends StatelessWidget {
  final VoidCallback onReportTap;
  final VoidCallback onReloadTap;

  const RouteActionsBar({
    super.key,
    required this.onReportTap,
    required this.onReloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: CupertinoIcons.doc_chart_fill,
            label: 'تقرير الخط',
            filled: false,
            onTap: onReportTap,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _ActionButton(
            icon: CupertinoIcons.arrow_2_circlepath,
            label: 'إعادة تحميل العربية',
            filled: true,
            onTap: onReloadTap,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryGreen : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: filled ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: filled ? Colors.white : AppColors.primaryGreen,
                  size: 18.sp),
              SizedBox(height: 6.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: filled ? Colors.white : AppColors.primary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
