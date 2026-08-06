import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.route_outlined,
            label: 'بدء خط السير',
            filled: true,
            onTap: () {},
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'فاتورة سريعة',
            filled: false,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryGreen : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: filled ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: filled ? Colors.white : AppColors.primaryGreen,
                size: 22.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: filled ? Colors.white : AppColors.primary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
