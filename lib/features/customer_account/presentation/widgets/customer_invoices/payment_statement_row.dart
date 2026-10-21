import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/breakdown_line.dart';

class PaymentStatementRow extends StatefulWidget {
  final PaymentBreakdown payment;

  const PaymentStatementRow({super.key, required this.payment});

  @override
  State<PaymentStatementRow> createState() => _PaymentStatementRowState();
}

class _PaymentStatementRowState extends State<PaymentStatementRow> {
  bool _expanded = false;

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final payment = widget.payment;
    final date = payment.collectedAt.toLocal();
    final dateLabel =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final ownCode = payment.ownInvoiceCode;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.textMuted,
                  size: 18.sp,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.code,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 12.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        ownCode == null
                            ? dateLabel
                            : '$dateLabel  •  مع الفاتورة $ownCode',
                        style: AppTextStyles.almaraiRegular14
                            .copyWith(color: colors.textMuted, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_amount(payment.total)} ج.م',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 12.sp),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'تحصيل',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.primary, fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (final line in payment.lines)
                  BreakdownLine(line: line, amountText: _amount(line.amount)),
                Divider(color: colors.border, height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'إجمالي التحصيل',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 11.sp),
                      ),
                    ),
                    Text(
                      '${_amount(payment.total)} ج.م',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.primary, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
