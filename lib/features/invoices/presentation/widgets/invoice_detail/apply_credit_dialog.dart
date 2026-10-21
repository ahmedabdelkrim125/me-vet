import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';

class ApplyCreditDialog extends StatefulWidget {
  final double maxAmount;
  final double remaining;

  const ApplyCreditDialog({
    super.key,
    required this.maxAmount,
    required this.remaining,
  });

  @override
  State<ApplyCreditDialog> createState() => _ApplyCreditDialogState();
}

class _ApplyCreditDialogState extends State<ApplyCreditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.maxAmount.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.maxAmount;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final parsed = double.tryParse(value.text.trim());
        final valid = parsed != null && parsed > 0 && parsed <= maxAmount;

        return AlertDialog(
          title: const Text('سداد من رصيد العميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المتبقي على الفاتورة: ${widget.remaining.toStringAsFixed(0)} ج.م',
              ),
              const SizedBox(height: 4),
              Text('رصيد العميل المتاح: ${maxAmount.toStringAsFixed(0)} ج.م'),
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
                  labelText: 'المبلغ المسدد من الرصيد',
                  suffixText: 'ج.م',
                  border: const OutlineInputBorder(),
                  errorText: parsed != null && parsed > maxAmount
                      ? 'أكبر من الرصيد المتاح'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'المبلغ هيتحسب مدفوع على الفاتورة من فلوس العميل الموجودة عندنا، ومش هيدخل خزنة جديدة.',
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
              child: const Text('تأكيد السداد'),
            ),
          ],
        );
      },
    );
  }
}
