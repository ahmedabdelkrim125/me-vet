import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/payment_method_selector.dart';

typedef EditPaidInput = ({
  double amount,
  bool extraPaid,
  PaymentMethod method,
});

class EditPaidAmountDialog extends StatefulWidget {
  final double total;
  final double paid;

  const EditPaidAmountDialog({
    super.key,
    required this.total,
    required this.paid,
  });

  @override
  State<EditPaidAmountDialog> createState() => _EditPaidAmountDialogState();
}

class _EditPaidAmountDialogState extends State<EditPaidAmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.total));
  final ValueNotifier<PaymentMethod> _method =
      ValueNotifier<PaymentMethod>(PaymentMethod.cash);
  final ValueNotifier<bool> _extraPaid = ValueNotifier<bool>(false);

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  double? _parse(String text) {
    final value = double.tryParse(text.trim());
    if (value == null) return null;
    return double.parse(value.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    _method.dispose();
    _extraPaid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: context.colors.textMuted,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final parsed = _parse(value.text);
        final isIncrease = parsed != null && parsed > widget.total;
        final isDecrease = parsed != null && parsed < widget.total;
        final valid =
            parsed != null && parsed > 0 && (isIncrease || isDecrease);

        return AlertDialog(
          title: const Text('تعديل مبلغ الفاتورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('مبلغ الفاتورة الحالي: ${_format(widget.total)} ج.م'),
                const SizedBox(height: 4),
                Text('المدفوع حاليًا: ${_format(widget.paid)} ج.م'),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'المبلغ النهائي الجديد',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المبلغ القديم هيتشال وهيتحط مكانه المبلغ ده في الفاتورة والـ PDF.',
                  style: mutedStyle,
                ),
                if (isIncrease) ...[
                  const SizedBox(height: 12),
                  Text(
                    'الفاتورة زادت ${_format(parsed - widget.total)} ج.م، العميل دفع الفرق؟',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _extraPaid,
                    builder: (context, extraPaid, _) => Column(
                      children: [
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: true,
                          groupValue: extraPaid,
                          onChanged: (v) => _extraPaid.value = v ?? false,
                          title: const Text('دفع الفرق'),
                        ),
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: false,
                          groupValue: extraPaid,
                          onChanged: (v) => _extraPaid.value = v ?? false,
                          title:
                              const Text('لسه ماتدفعش (يتحسب دين على العميل)'),
                        ),
                        if (extraPaid)
                          ValueListenableBuilder<PaymentMethod>(
                            valueListenable: _method,
                            builder: (context, method, _) =>
                                PaymentMethodSelector(
                              value: method,
                              onChanged: (selected) => _method.value = selected,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (isDecrease) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.paid > parsed
                        ? '${_format(widget.paid - parsed)} ج.م هيفضلوا رصيد دائن للعميل.'
                        : 'المتبقي على العميل هيقل ${_format(widget.total - parsed)} ج.م.',
                    style: mutedStyle,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: valid
                  ? () => Navigator.pop<EditPaidInput>(
                        context,
                        (
                          amount: parsed,
                          extraPaid: isIncrease && _extraPaid.value,
                          method: _method.value,
                        ),
                      )
                  : null,
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }
}
