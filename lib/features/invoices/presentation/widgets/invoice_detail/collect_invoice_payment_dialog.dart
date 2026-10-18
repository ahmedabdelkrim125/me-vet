import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/payment_method_selector.dart';

typedef CollectPaymentInput = ({double? amount, PaymentMethod method});

class CollectInvoicePaymentDialog extends StatefulWidget {
  final double remaining;

  const CollectInvoicePaymentDialog({super.key, required this.remaining});

  @override
  State<CollectInvoicePaymentDialog> createState() =>
      _CollectInvoicePaymentDialogState();
}

class _CollectInvoicePaymentDialogState
    extends State<CollectInvoicePaymentDialog> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.remaining > 0 ? widget.remaining.toStringAsFixed(0) : '',
  );
  final ValueNotifier<PaymentMethod> _method =
      ValueNotifier<PaymentMethod>(PaymentMethod.cash);

  @override
  void dispose() {
    _amountController.dispose();
    _method.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.pop<CollectPaymentInput>(context, (
      amount: double.tryParse(_amountController.text.trim()),
      method: _method.value,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المبلغ المدفوع'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المتبقي حاليًا: ${widget.remaining.toStringAsFixed(0)} ج.م'),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'المبلغ المحصّل دلوقتي',
              border: OutlineInputBorder(),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountController,
            builder: (context, value, _) {
              final parsed = double.tryParse(value.text.trim());
              if (parsed == null || parsed <= widget.remaining) {
                return const SizedBox.shrink();
              }
              final excess = parsed - widget.remaining;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${excess.toStringAsFixed(0)} ج.م زيادة عن المتبقي، هتتسجل رصيد دائن للعميل.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textMuted,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<PaymentMethod>(
            valueListenable: _method,
            builder: (context, method, _) => PaymentMethodSelector(
              value: method,
              onChanged: (value) => _method.value = value,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('تأكيد التحصيل'),
        ),
      ],
    );
  }
}
