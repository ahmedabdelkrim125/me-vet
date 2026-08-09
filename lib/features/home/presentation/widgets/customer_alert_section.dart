import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/customer_alert_model.dart';

class CustomerAlertSection extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final Color accentColor;
  final List<CustomerAlertModel> customers;

  const CustomerAlertSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.customers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: accentColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: context.colors.primary,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              Text(
                '${customers.length}',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: accentColor,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (int i = 0; i < customers.length; i++) ...[
            _CustomerRow(customer: customers[i], accentColor: accentColor),
            if (i != customers.length - 1) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerAlertModel customer;
  final Color accentColor;

  const _CustomerRow({required this.customer, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedStore01,
            color: accentColor,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: context.colors.text,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                customer.subtitle,
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: context.colors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: context.colors.textMuted,
          size: 18.sp,
        ),
      ],
    );
  }
}
