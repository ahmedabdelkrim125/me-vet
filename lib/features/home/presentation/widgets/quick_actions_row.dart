import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
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
            icon: HugeIcons.strokeRoundedRoute01,
            label: 'بدء خط السير',
            filled: true,
            onTap: () {},
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: HugeIcons.strokeRoundedInvoice01,
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
  final List<List<dynamic>> icon;
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
      color: filled ? context.colors.primary : context.colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: filled ? null : Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              HugeIcon(
                icon: icon,
                color: filled ? Colors.white : context.colors.primary,
                size: 22.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: filled ? Colors.white : context.colors.primary,
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
