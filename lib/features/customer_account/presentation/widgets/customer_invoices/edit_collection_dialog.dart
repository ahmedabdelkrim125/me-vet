import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';

typedef EditCollectionInput = ({double amount, String reason});

class EditCollectionDialog extends StatefulWidget {
  final PaymentBreakdown payment;

  const EditCollectionDialog({super.key, required this.payment});

  @override
  State<EditCollectionDialog> createState() => _EditCollectionDialogState();
}

class _EditCollectionDialogState extends State<EditCollectionDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: _format(widget.payment.total));
  final TextEditingController _reason = TextEditingController();

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
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(fontSize: 12, color: context.colors.textMuted);
    final current = widget.payment.total;

    return ListenableBuilder(
      listenable: Listenable.merge([_amount, _reason]),
      builder: (context, _) {
        final parsed = _parse(_amount.text);
        final amount = parsed ?? 0.0;
        final changed = parsed != null && (parsed - current).abs() >= 0.005;
        final isIncrease = changed && amount > current;
        final isDecrease = changed && amount < current;
        final valid = amount > 0 && changed && _reason.text.trim().length >= 3;

        return AlertDialog(
          title: const Text('تعديل التحصيل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('رقم التحصيل: ${widget.payment.code}'),
                const SizedBox(height: 4),
                Text('المبلغ الحالي: ${_format(current)} ج.م'),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'المبلغ الصحيح',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isDecrease) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_format(current - amount)} ج.م هيتشالوا من التحصيل، ومديونية العميل هتزيد بنفس القيمة.',
                    style: mutedStyle,
                  ),
                ],
                if (isIncrease) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_format(amount - current)} ج.م هيتضافوا للتحصيل وهيتخصموا من مديونية العميل، والزيادة لازم متعديش المديونية الحالية.',
                    style: mutedStyle,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل',
                    hintText: 'مثال: زوّدت صفر بالغلط',
                    border: OutlineInputBorder(),
                  ),
                ),
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
                  ? () => Navigator.pop<EditCollectionInput>(
                        context,
                        (amount: amount, reason: _reason.text.trim()),
                      )
                  : null,
              child: const Text('حفظ التعديل'),
            ),
          ],
        );
      },
    );
  }
}
