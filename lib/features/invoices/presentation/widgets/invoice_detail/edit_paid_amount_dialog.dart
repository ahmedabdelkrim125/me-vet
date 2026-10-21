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
        final overTotalOnDecrease = isDecrease && parsed > widget.total;
        final valid = parsed != null &&
            parsed >= 0 &&
            !overTotalOnDecrease &&
            (isIncrease || isDecrease);

        return AlertDialog(
          title: const Text('تعديل المبلغ المدفوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إجمالي الفاتورة: ${_format(widget.total)} ج.م'),
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
                decoration: InputDecoration(
                  labelText: 'المبلغ المدفوع الجديد',
                  suffixText: 'ج.م',
                  border: const OutlineInputBorder(),
                  errorText: overTotalOnDecrease
                      ? 'عند التخفيض لازم يكون أقل من أو يساوي إجمالي الفاتورة'
                      : null,
                ),
              ),
              if (isIncrease) ...[
                const SizedBox(height: 8),
                Text(
                  'هيتسجّل تحصيل ${_format(parsed - widget.paid)} ج.م على الفاتورة.',
                  style: mutedStyle,
                ),
                if (parsed > widget.total)
                  Text(
                    '${_format(parsed - widget.total)} ج.م زيادة عن إجمالي الفاتورة، هتتسجل رصيد دائن للعميل.',
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
              if (isDecrease && !overTotalOnDecrease) ...[
                const SizedBox(height: 8),
                Text(
                  '${_format(widget.paid - parsed)} ج.م هيفضلوا رصيد دائن للعميل، يقدر ياخد بيهم منتجات في فواتير جاية أو يتردوله.',
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
