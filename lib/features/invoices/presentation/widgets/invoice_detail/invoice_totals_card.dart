import 'package:flutter/material.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';

class InvoiceTotalsCard extends StatelessWidget {
  final InvoiceFullDetail detail;

  const InvoiceTotalsCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return InvoiceInfoCard(
      children: [
        InvoiceInfoRow(
          label: 'الإجمالي قبل الخصم',
          value: '${detail.subtotal.toStringAsFixed(0)} ج.م',
        ),
        if (detail.discountPercent > 0)
          InvoiceInfoRow(
            label: 'الخصم',
            value: '${detail.discountPercent.toStringAsFixed(0)}%',
          ),
        InvoiceInfoRow(
          label: 'الإجمالي',
          value: '${detail.totalAmount.toStringAsFixed(0)} ج.م',
          highlight: true,
        ),
        InvoiceInfoRow(
          label: 'المدفوع الآن',
          value: '${detail.paidNow.toStringAsFixed(0)} ج.م',
        ),
        InvoiceInfoRow(
          label: 'المتبقي على العميل',
          value:
              '${(detail.remaining < 0 ? 0 : detail.remaining).toStringAsFixed(0)} ج.م',
        ),
      ],
    );
  }
}
