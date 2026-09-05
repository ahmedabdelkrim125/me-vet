import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class AccountSummaryCard extends StatelessWidget {
  final String customerName;
  final double balance;

  const AccountSummaryCard({
    super.key,
    required this.customerName,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String statusLabel;
    final Color statusColor;
    if (balance > 0) {
      statusLabel = 'مستحق على العميل';
      statusColor = colors.statusNotReached;
    } else if (balance < 0) {
      statusLabel = 'رصيد دائن للعميل';
      statusColor = colors.primary;
    } else {
      statusLabel = 'الحساب مسدد';
      statusColor = colors.primary;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customerName,
              style: AppTextStyles.cairoBold18.copyWith(color: colors.text, fontSize: 15.sp)),
          SizedBox(height: 10.h),
          Text('${balance.abs().toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoBold18.copyWith(color: statusColor, fontSize: 24.sp)),
          SizedBox(height: 4.h),
          Text(statusLabel,
              style: AppTextStyles.cairoMedium16.copyWith(color: statusColor, fontSize: 12.sp)),
        ],
      ),
    );
  }
}