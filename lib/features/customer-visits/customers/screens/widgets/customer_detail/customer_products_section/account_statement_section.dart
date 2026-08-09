import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../domain/models/customer_detail_model.dart';
import 'invoice_row.dart';

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
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPrinter,
                  color: colors.textMuted,
                  size: 18.sp,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedShare08,
                  color: colors.primary,
                  size: 18.sp,
                ),
              ),
            ],
          ),
          for (final invoice in invoices)
            InvoiceRow(invoice: invoice, colors: colors),
        ],
      ),
    );
  }
}
