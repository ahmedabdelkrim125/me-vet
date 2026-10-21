import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';

class InvoiceOldDebtSection extends StatelessWidget {
  final InvoiceFullDetail detail;
  final List<PaymentBreakdownLine> lines;

  const InvoiceOldDebtSection({
    super.key,
    required this.detail,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final oldDebtTotal = lines.fold(0.0, (sum, line) => sum + line.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'دين قديم اتحصّل مع الفاتورة دي',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: colors.text,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        InvoiceInfoCard(
          children: [
            for (final line in lines)
              InvoiceInfoRow(
                label: line.invoiceCode ?? 'رصيد سابق',
                value: '${line.amount.toStringAsFixed(0)} ج.م',
              ),
            InvoiceInfoRow(
              label: 'إجمالي التحصيل مع الفاتورة',
              value:
                  '${(detail.paidNow + oldDebtTotal).toStringAsFixed(0)} ج.م',
              highlight: true,
            ),
          ],
        ),
      ],
    );
  }
}
