import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';

class CustomerQuickActionsBar extends StatelessWidget {
  final CustomerModel customer;

  const CustomerQuickActionsBar({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _ActionItem(
                icon: CupertinoIcons.cart_fill,
                label: 'فاتورة',
                color: AppColors.primaryGreen,
                onTap: () {})),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActionItem(
                icon: CupertinoIcons.money_dollar_circle_fill,
                label: 'تحصيل',
                color: AppColors.statBlue,
                onTap: () {})),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActionItem(
                icon: CupertinoIcons.phone_fill,
                label: 'اتصال',
                color: AppColors.primary,
                onTap: () {})),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActionItem(
                icon: CupertinoIcons.chat_bubble_2_fill,
                label: 'واتساب',
                color: AppColors.statOrange,
                onTap: () {})),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActionItem(
                icon: CupertinoIcons.location_solid,
                label: 'الموقع',
                color: AppColors.statusNotReached,
                onTap: () {})),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(height: 6.h),
              Text(label,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: AppColors.primary, fontSize: 10.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
