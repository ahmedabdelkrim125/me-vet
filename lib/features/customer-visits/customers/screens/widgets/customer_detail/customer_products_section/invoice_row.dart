import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../domain/models/customer_detail_model.dart';

class InvoiceRow extends StatelessWidget {
  final InvoiceSummaryModel invoice;
  final AppColorScheme colors;

  const InvoiceRow({super.key, required this.invoice, required this.colors});

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
