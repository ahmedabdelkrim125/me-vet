import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_totals_row.dart';

class InvoiceAccountSummarySection extends StatelessWidget {
  final double previousBalance;
  final double invoiceTotal;
  final TextEditingController paidController;
  final ValueChanged<String> onPaidChanged;
  final double remaining;

  const InvoiceAccountSummarySection({
    super.key,
    required this.previousBalance,
    required this.invoiceTotal,
    required this.paidController,
    required this.onPaidChanged,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalDue = previousBalance + invoiceTotal;
    final payableDue = totalDue > 0 ? totalDue : 0.0;
    final hasCredit = previousBalance < 0;
    final coveredByCredit = totalDue <= 0.005;
    final isSettled = remaining <= 0.005;
    final paid = double.tryParse(paidController.text) ?? 0;
    final isFullyDeferred = paid <= 0.005;

    final String infoText;
    final Color infoColor;
    final IconData infoIcon;
    if (coveredByCredit) {
      infoText =
          'مفيش مبلغ مطلوب دفعه — هيتخصم ${formatMoney(invoiceTotal)} من رصيد العميل الدائن، ويفضل له ${formatMoney(-totalDue)}.';
      infoColor = colors.primary;
      infoIcon = Icons.account_balance_wallet_outlined;
    } else if (hasCredit) {
      infoText =
          'هيتخصم ${formatMoney(-previousBalance)} من رصيد العميل الدائن، والباقي ${formatMoney(totalDue)} هيتضاف لرصيده المستحق.';
      infoColor = colors.statOrange;
      infoIcon = Icons.schedule_rounded;
    } else {
      infoText =
          'العميل لم يدفع أي مبلغ — سيتم تسجيل الفاتورة كفاتورة آجلة بالكامل وإضافة ${formatMoney(totalDue)} إلى رصيد العميل المستحق.';
      infoColor = colors.statOrange;
      infoIcon = Icons.schedule_rounded;
    }

    final String? warning = paid > payableDue + 0.01
        ? 'المبلغ المدفوع يتجاوز إجمالي المستحق على العميل'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InvoiceSectionTitle(
          icon: Icons.account_balance_wallet_outlined,
          title: 'ملخص الحساب',
        ),
        SizedBox(height: 12.h),
        InvoiceTotalsRow(
            label: 'قيمة الفاتورة الحالية', value: formatMoney(invoiceTotal)),
        SizedBox(height: 8.h),
        InvoiceTotalsRow(
          label: hasCredit ? 'رصيد العميل السابق (دائن)' : 'الحساب السابق',
          value: formatMoney(previousBalance.abs()),
        ),
        SizedBox(height: 10.h),
        Divider(height: 1, color: colors.border),
        SizedBox(height: 10.h),
        InvoiceTotalsRow(
          label: totalDue < 0
              ? 'رصيد العميل بعد الفاتورة (دائن)'
              : 'إجمالي المستحق على العميل',
          value: formatMoney(totalDue.abs()),
        ),
        SizedBox(height: 14.h),
        Text(
          'المدفوع الآن',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: paidController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: onPaidChanged,
          style: AppTextStyles.cairoMedium16.copyWith(color: colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.background,
            prefixIcon: Icon(Icons.payments_outlined,
                size: 18.sp, color: colors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: warning != null
                    ? colors.statusNotReached
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color:
                    warning != null ? colors.statusNotReached : colors.primary,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            suffixIcon: TextButton(
              onPressed: () {
                paidController.text = payableDue.toStringAsFixed(2);
                onPaidChanged(paidController.text);
              },
              child: Text('تعبئة كاملة',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.primary, fontSize: 11.sp)),
            ),
          ),
        ),
        if (warning != null) ...[
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  size: 14.sp, color: colors.statusNotReached),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  warning,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: colors.statusNotReached, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ],
        if (isFullyDeferred) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: infoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: infoColor.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(infoIcon, size: 16.sp, color: infoColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    infoText,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: infoColor, fontSize: 11.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: (isSettled ? colors.primary : colors.statusNotReached)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Text('المتبقي على العميل',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
              const Spacer(),
              Text(
                formatMoney(remaining),
                style: AppTextStyles.cairoBold18.copyWith(
                  color: isSettled ? colors.primary : colors.statusNotReached,
                  fontSize: 17.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
