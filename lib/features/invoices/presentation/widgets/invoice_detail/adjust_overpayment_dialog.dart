import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';

class AdjustOverpaymentDialog extends StatefulWidget {
  final double total;
  final double paid;

  const AdjustOverpaymentDialog({
    super.key,
    required this.total,
    required this.paid,
  });

  @override
  State<AdjustOverpaymentDialog> createState() =>
      _AdjustOverpaymentDialogState();
}

class _AdjustOverpaymentDialogState extends State<AdjustOverpaymentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.total.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.total;
    final paid = widget.paid;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final parsed = double.tryParse(value.text.trim());
        final valid =
            parsed != null && parsed >= 0 && parsed <= total && parsed < paid;
        final overLimit = parsed != null && parsed > total;
        final excess = valid ? paid - parsed : 0.0;

        return AlertDialog(
          title: const Text('تعديل المبلغ المدفوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إجمالي الفاتورة: ${total.toStringAsFixed(0)} ج.م'),
              const SizedBox(height: 4),
              Text('المدفوع حاليًا: ${paid.toStringAsFixed(0)} ج.م'),
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
                  errorText: overLimit
                      ? 'أكبر من إجمالي الفاتورة'
                      : (parsed != null && parsed >= paid
                          ? 'لازم يكون أقل من المدفوع حاليًا'
                          : null),
                ),
              ),
              const SizedBox(height: 12),
              if (valid)
                Text(
                  '${excess.toStringAsFixed(0)} ج.م هيفضلوا رصيد دائن للعميل، يقدر ياخد بيهم منتجات في فواتير جاية أو يتردوله.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textMuted,
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
              onPressed: valid ? () => Navigator.pop(context, parsed) : null,
              child: const Text('تأكيد التعديل'),
            ),
          ],
        );
      },
    );
  }
}
