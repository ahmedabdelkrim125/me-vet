import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_detail_model.dart';

class CustomerFinancialInfoCard extends StatelessWidget {
  final CustomerDetailModel detail;

  const CustomerFinancialInfoCard({super.key, required this.detail});

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final customer = detail.customer;
    final creditUsage = customer.creditLimit == 0
        ? 0.0
        : (detail.currentBalance / customer.creditLimit).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: _InfoTile(
                      label: 'الرصيد الحالي',
                      value:
                          '${detail.currentBalance.toStringAsFixed(0)} ج.م')),
              Expanded(
                  child: _InfoTile(
                      label: 'حد الائتمان',
                      value: '${customer.creditLimit.toStringAsFixed(0)} ج.م')),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'آخر تحصيل',
                  value: detail.lastCollectionDate == null
                      ? '—'
                      : _formatDate(detail.lastCollectionDate!),
                ),
              ),
              Expanded(
                  child: _InfoTile(
                      label: 'متوسط الطلب',
                      value: '${detail.averageOrder.toStringAsFixed(0)} ج.م')),
            ],
          ),
          SizedBox(height: 14.h),
          Text('استهلاك حد الائتمان',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: AppColors.navInactive, fontSize: 11.sp)),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: creditUsage,
              minHeight: 8.h,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation(creditUsage > 0.8
                  ? AppColors.statusNotReached
                  : AppColors.primaryGreen),
            ),
          ),
          SizedBox(height: 14.h),
          Text('البيانات الأساسية',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: AppColors.primary, fontSize: 12.sp)),
          SizedBox(height: 8.h),
          _InfoRow(
              label: 'الهاتف',
              value: customer.phone.isEmpty ? '—' : customer.phone),
          _InfoRow(
              label: 'العنوان',
              value:
                  customer.address.isEmpty ? customer.area : customer.address),
          _InfoRow(label: 'التصنيف', value: customer.category),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: AppColors.navInactive, fontSize: 10.sp)),
        SizedBox(height: 4.h),
        Text(value,
            style: AppTextStyles.cairoBold18
                .copyWith(color: AppColors.primary, fontSize: 14.sp)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: AppColors.navInactive, fontSize: 11.sp)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: AppColors.primary, fontSize: 11.sp)),
        ],
      ),
    );
  }
}
