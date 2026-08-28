import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_detail_model.dart';

class CustomerAccountStatementSection extends StatelessWidget {
  final List<InvoiceSummaryModel> invoices;

  const CustomerAccountStatementSection({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              Text('كشف الحساب (آخر 6 شهور)',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
              const Spacer(),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.print_outlined,
                      color: colors.textMuted, size: 18.sp)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined,
                      color: colors.primary, size: 18.sp)),
            ],
          ),
          if (invoices.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                'لسه مفيش فواتير مسجلة للعميل ده',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 11.sp),
              ),
            )
          else
            for (final invoice in invoices)
              _InvoiceRow(invoice: invoice, colors: colors),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceSummaryModel invoice;
  final AppColorScheme colors;

  const _InvoiceRow({required this.invoice, required this.colors});

  Color get _statusColor {
    switch (invoice.status) {
      case 'مدفوعة':
        return colors.primary;
      case 'جزئي':
        return colors.statOrange;
      default:
        return colors.statusNotReached;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.code,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(
                  '${invoice.date.year}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.day.toString().padLeft(2, '0')}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          Text('${invoice.amount.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 12.sp)),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(invoice.status,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: _statusColor, fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }
}
