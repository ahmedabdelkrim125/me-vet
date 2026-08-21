import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_detail_model.dart';
import 'customer_products_section/info_row.dart';
import 'customer_products_section/info_tile.dart';

class CustomerFinancialInfoCard extends StatelessWidget {
  final CustomerDetailModel detail;

  const CustomerFinancialInfoCard({super.key, required this.detail});

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final customer = detail.customer;
    final creditUsage = customer.creditLimit == 0
        ? 0.0
        : (customer.currentBalance / customer.creditLimit).clamp(0.0, 1.0);

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
              Expanded(
                child: InfoTile(
                  label: 'المديونية الحالية',
                  value: '${customer.currentBalance.toStringAsFixed(0)} ج.م',
                ),
              ),
              Expanded(
                child: InfoTile(
                  label: 'حد الائتمان',
                  value: '${customer.creditLimit.toStringAsFixed(0)} ج.م',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InfoTile(
                  label: 'آخر تحصيل',
                  value: customer.lastCollectionDate == null
                      ? '—'
                      : _formatDate(customer.lastCollectionDate!),
                ),
              ),
              Expanded(
                child: InfoTile(
                  label: 'متوسط الطلب',
                  value: detail.averageOrder == 0
                      ? '—'
                      : '${detail.averageOrder.toStringAsFixed(0)} ج.م',
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text('استهلاك حد الائتمان',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.textMuted, fontSize: 11.sp)),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: creditUsage,
              minHeight: 8.h,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(
                  creditUsage > 0.8 ? colors.statusNotReached : colors.primary),
            ),
          ),
          SizedBox(height: 14.h),
          Text('البيانات الأساسية',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 12.sp)),
          SizedBox(height: 8.h),
          InfoRow(
            label: 'الهاتف',
            value: customer.phone.isEmpty ? '—' : customer.phone,
          ),
          InfoRow(
            label: 'العنوان',
            value: customer.address.isEmpty ? customer.area : customer.address,
          ),
          InfoRow(label: 'التصنيف', value: customer.category),
        ],
      ),
    );
  }
}
