// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

// class InvoicePaymentActions extends StatelessWidget {
//   final InvoiceFullDetail detail;
//   final double applicableCredit;
//   final VoidCallback onCollectPayment;
//   final VoidCallback onAdjustOverpayment;
//   final VoidCallback onApplyCredit;

//   const InvoicePaymentActions({
//     super.key,
//     required this.detail,
//     required this.applicableCredit,
//     required this.onCollectPayment,
//     required this.onAdjustOverpayment,
//     required this.onApplyCredit,
//   });

//   Widget _button({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required Widget label,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(top: 8.h),
//       child: SizedBox(
//         width: double.infinity,
//         child: OutlinedButton.icon(
//           onPressed: onPressed,
//           icon: Icon(icon, size: 16),
//           label: label,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _button(
//           onPressed: onCollectPayment,
//           icon: Icons.edit_outlined,
//           label: const Text('تعديل المبلغ المدفوع'),
//         ),
//         if (detail.remaining > 0 && applicableCredit > 0)
//           _button(
//             onPressed: onApplyCredit,
//             icon: Icons.account_balance_wallet_outlined,
//             label: Text(
//               'سداد من رصيد العميل (${applicableCredit.toStringAsFixed(0)} ج.م)',
//             ),
//           ),
//         if (detail.paidNow > detail.totalAmount)
//           _button(
//             onPressed: onAdjustOverpayment,
//             icon: Icons.undo_rounded,
//             label: const Text('تخفيض المبلغ المدفوع'),
//           ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

class InvoicePaymentActions extends StatelessWidget {
  final InvoiceFullDetail detail;
  final double applicableCredit;
  final VoidCallback onCollectPayment;
  final VoidCallback onApplyCredit;

  const InvoicePaymentActions({
    super.key,
    required this.detail,
    required this.applicableCredit,
    required this.onCollectPayment,
    required this.onApplyCredit,
  });

  Widget _button({
    required VoidCallback onPressed,
    required IconData icon,
    required Widget label,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _button(
          onPressed: onCollectPayment,
          icon: Icons.edit_outlined,
          label: const Text('تعديل المبلغ المدفوع'),
        ),
        if (detail.remaining > 0 && applicableCredit > 0)
          _button(
            onPressed: onApplyCredit,
            icon: Icons.account_balance_wallet_outlined,
            label: Text(
              'سداد من رصيد العميل (${applicableCredit.toStringAsFixed(0)} ج.م)',
            ),
          ),
      ],
    );
  }
}
