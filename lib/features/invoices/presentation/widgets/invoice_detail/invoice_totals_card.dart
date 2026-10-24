// import 'package:flutter/material.dart';
// import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
// import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
// import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';

// class InvoiceTotalsCard extends StatelessWidget {
//   final InvoiceFullDetail detail;
//   final InvoiceAccountSummary? accountSummary;

//   const InvoiceTotalsCard({
//     super.key,
//     required this.detail,
//     this.accountSummary,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final summary = accountSummary;
//     final paid = summary?.paidFor(detail.totalAmount) ?? detail.paidNow;
//     final remaining = summary?.remaining ?? detail.remaining;
//     final previousBalance = summary?.previousBalance;
//     final isCredit = previousBalance != null && previousBalance < 0;
//     final accountTotal = (previousBalance ?? 0) + detail.totalAmount;
//     return InvoiceInfoCard(
//       children: [
//         InvoiceInfoRow(
//           label: 'الإجمالي قبل الخصم',
//           value: '${detail.subtotal.toStringAsFixed(0)} ج.م',
//         ),
//         if (detail.discountPercent > 0)
//           InvoiceInfoRow(
//             label: 'الخصم',
//             value: '${detail.discountPercent.toStringAsFixed(0)}%',
//           ),
//         InvoiceInfoRow(
//           label: 'الإجمالي',
//           value: '${detail.totalAmount.toStringAsFixed(0)} ج.م',
//           highlight: true,
//         ),
//         if (previousBalance != null) ...[
//           InvoiceInfoRow(
//             label:
//                 isCredit ? 'رصيد العميل السابق (دائن)' : 'الرصيد السابق للعميل',
//             value: '${previousBalance.abs().toStringAsFixed(0)} ج.م',
//           ),
//           if (previousBalance.abs() > 0.005)
//             InvoiceInfoRow(
//               label: accountTotal < 0
//                   ? 'رصيد العميل بعد الفاتورة (دائن)'
//                   : 'إجمالي الحساب',
//               value: '${accountTotal.abs().toStringAsFixed(0)} ج.م',
//             ),
//         ],
//         InvoiceInfoRow(
//           label: 'المدفوع الآن',
//           value: '${paid.toStringAsFixed(0)} ج.م',
//         ),
//         if (remaining < -0.005)
//           InvoiceInfoRow(
//             label: 'رصيد للعميل (دائن)',
//             value: '${(-remaining).toStringAsFixed(0)} ج.م',
//           )
//         else
//           InvoiceInfoRow(
//             label: 'المتبقي على العميل',
//             value: '${remaining.toStringAsFixed(0)} ج.م',
//           ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';

class InvoiceTotalsCard extends StatelessWidget {
  final InvoiceFullDetail detail;
  final InvoiceAccountSummary? accountSummary;
  final double laterCollections;

  const InvoiceTotalsCard({
    super.key,
    required this.detail,
    this.accountSummary,
    this.laterCollections = 0,
  });

  @override
  Widget build(BuildContext context) {
    final summary = accountSummary;
    final paid = summary?.totalPaid ?? detail.paidNow;
    final remaining = summary?.remaining ?? detail.remaining;
    final previousBalance = summary?.previousBalance;
    final isCredit = previousBalance != null && previousBalance < 0;
    final accountTotal = (previousBalance ?? 0) + detail.totalAmount;
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
        if (previousBalance != null) ...[
          InvoiceInfoRow(
            label:
                isCredit ? 'رصيد العميل السابق (دائن)' : 'الرصيد السابق للعميل',
            value: '${previousBalance.abs().toStringAsFixed(0)} ج.م',
          ),
          if (previousBalance.abs() > 0.005)
            InvoiceInfoRow(
              label: accountTotal < 0
                  ? 'رصيد العميل بعد الفاتورة (دائن)'
                  : 'إجمالي الحساب',
              value: '${accountTotal.abs().toStringAsFixed(0)} ج.م',
            ),
        ],
        InvoiceInfoRow(
          label: 'المدفوع الآن',
          value: '${paid.toStringAsFixed(0)} ج.م',
        ),
        if (laterCollections > 0.005)
          InvoiceInfoRow(
            label: 'تحصيلات لاحقة على الفاتورة',
            value: '${laterCollections.toStringAsFixed(0)} ج.م',
          ),
        if (remaining < -0.005)
          InvoiceInfoRow(
            label: 'رصيد للعميل (دائن)',
            value: '${(-remaining).toStringAsFixed(0)} ج.م',
          )
        else
          InvoiceInfoRow(
            label: 'المتبقي على العميل',
            value: '${remaining.toStringAsFixed(0)} ج.م',
          ),
      ],
    );
  }
}
