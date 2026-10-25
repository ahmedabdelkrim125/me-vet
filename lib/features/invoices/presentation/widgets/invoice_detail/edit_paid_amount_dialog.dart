import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/payment_method_selector.dart';

typedef EditPaidInput = ({double amount, PaymentMethod method});

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
      TextEditingController(text: _format(widget.paid));
  final ValueNotifier<PaymentMethod> _method =
      ValueNotifier<PaymentMethod>(PaymentMethod.cash);

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
        final isIncrease = parsed != null && parsed > widget.paid;
        final isDecrease = parsed != null && parsed < widget.paid;
        final valid =
            parsed != null && parsed >= 0 && (isIncrease || isDecrease);

        return AlertDialog(
          title: const Text('تعديل المبلغ المدفوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إجمالي الفاتورة: ${_format(widget.total)} ج.م'),
              const SizedBox(height: 4),
              Text('إجمالي المدفوع مع الفاتورة: ${_format(widget.paid)} ج.م'),
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
                  labelText: 'المبلغ المدفوع الجديد',
                  suffixText: 'ج.م',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isIncrease) ...[
                const SizedBox(height: 8),
                Text(
                  'هيتسجّل تحصيل ${_format(parsed - widget.paid)} ج.م على الفاتورة دي، وأي زيادة عن قيمتها بتتخصم من مديونية العميل السابقة، ولو مفيش مديونية بتبقى رصيد للعميل.',
                  style: mutedStyle,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<PaymentMethod>(
                  valueListenable: _method,
                  builder: (context, method, _) => PaymentMethodSelector(
                    value: method,
                    onChanged: (selected) => _method.value = selected,
                  ),
                ),
              ],
              if (isDecrease) ...[
                const SizedBox(height: 8),
                Text(
                  '${_format(widget.paid - parsed)} ج.م هيتشالوا من المدفوع مع الفاتورة دي، وهيرجعوا مستحقين على العميل.',
                  style: mutedStyle,
                ),
              ],
            ],
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
                        (amount: parsed, method: _method.value),
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
