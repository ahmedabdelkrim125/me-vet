import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

import '../../domain/entities/payment_method.dart';
import 'payment_method_selector.dart';

Future<bool?> showRefundCreditDialog(
  BuildContext context, {
  required String customerId,
  required String customerName,
  required double credit,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RefundCreditDialog(
      customerId: customerId,
      customerName: customerName,
      credit: credit,
    ),
  );
}

class _RefundCreditDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final double credit;

  const _RefundCreditDialog({
    required this.customerId,
    required this.customerName,
    required this.credit,
  });

  @override
  State<_RefundCreditDialog> createState() => _RefundCreditDialogState();
}

class _RefundCreditDialogState extends State<_RefundCreditDialog> {
  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.credit.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  bool get _valid {
    final amount = _amount;
    return amount != null && amount > 0 && amount <= widget.credit;
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount == null || !_valid || _submitting) return;

    setState(() => _submitting = true);
    try {
      await InvoicesRepository.instance.refundCustomerCredit(
        customerId: widget.customerId,
        amount: amount,
        paymentMethod: _method.backendValue,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = _amount;

    return AlertDialog(
      title: Text(
        'رد رصيد للعميل',
        style: AppTextStyles.cairoBold18
            .copyWith(color: colors.text, fontSize: 16.sp),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.customerName} — رصيده الدائن ${widget.credit.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _amountController,
              enabled: !_submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'المبلغ المردود',
                suffixText: 'ج.م',
                border: const OutlineInputBorder(),
                errorText: amount != null && amount > widget.credit
                    ? 'أكبر من رصيد العميل'
                    : null,
              ),
            ),
            SizedBox(height: 12.h),
            PaymentMethodSelector(
              value: _method,
              onChanged: (m) {
                if (!_submitting) setState(() => _method = m);
              },
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _notesController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'هيتسجل مصروف على نفس طريقة الدفع في تقرير اليوم، وهيتخصم من رصيد العميل.',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 11.sp),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: (_valid && !_submitting) ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تأكيد الرد'),
        ),
      ],
    );
  }
}
