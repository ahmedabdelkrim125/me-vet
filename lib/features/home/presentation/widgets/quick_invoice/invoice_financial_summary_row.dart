import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_financial_card.dart';

class InvoiceFinancialSummaryRow extends StatelessWidget {
  final InvoiceCustomerModel invoice;
  const InvoiceFinancialSummaryRow({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nearLimit =
        invoice.customer.currentBalance > invoice.customer.creditLimit * 0.8;
    return Row(
      children: [
        Expanded(
          child: InvoiceFinancialCard(
            title: 'الحد الائتماني',
            value: formatMoney(invoice.customer.creditLimit),
            icon: Icons.verified_user_outlined,
            color: colors.statBlue,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: InvoiceFinancialCard(
            title: 'الرصيد الحالي',
            value: formatMoney(invoice.customer.currentBalance),
            icon: Icons.account_balance_wallet_outlined,
            color: nearLimit ? colors.statusNotReached : colors.statOrange,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: InvoiceFinancialCard(
            title: 'تاريخ آخر سداد',
            value: formatDate(
                invoice.customer.lastCollectionDate ?? DateTime(2024, 6, 6)),
            icon: Icons.event_available_outlined,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}
