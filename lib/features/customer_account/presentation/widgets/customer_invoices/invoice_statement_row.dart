import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_record_model.dart';

class InvoiceStatementRow extends StatelessWidget {
  final InvoiceRecordModel invoice;
  final VoidCallback onTap;
  final double oldDebtCollected;
  final bool hasOldDebtSource;
  final String? collectedViaInvoiceCode;

  const InvoiceStatementRow({
    super.key,
    required this.invoice,
    required this.onTap,
    this.oldDebtCollected = 0,
    this.hasOldDebtSource = false,
    this.collectedViaInvoiceCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settledElsewhere =
        hasOldDebtSource && invoice.status == InvoiceStatus.paid;
    final statusColor = settledElsewhere
        ? colors.statOrange
        : switch (invoice.status) {
            InvoiceStatus.paid => colors.primary,
            InvoiceStatus.partial => colors.statOrange,
            InvoiceStatus.deferred => colors.statusNotReached,
          };
    final statusLabel = settledElsewhere ? 'محصّلة' : invoice.status.label;
    final date = invoice.date;
    final dateLabel =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final hasOldDebt = oldDebtCollected > 0;
    final totalWithOldDebt = invoice.amount + oldDebtCollected;

    final subtitle = hasOldDebt
        ? '$dateLabel  •  شامل دين قديم'
        : settledElsewhere && collectedViaInvoiceCode != null
            ? 'اتحصّلت مع الفاتورة $collectedViaInvoiceCode'
            : dateLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: colors.textMuted, size: 18.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.code,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 12.sp),
                      ),
                      if (invoice.isFromAdmin) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'من الإدارة',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.primary,
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Text(
              '${totalWithOldDebt.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 12.sp),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: statusColor, fontSize: 10.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
