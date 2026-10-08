import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditPriceDialog extends StatefulWidget {
  final double initialPrice;

  const EditPriceDialog({super.key, required this.initialPrice});

  @override
  State<EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<EditPriceDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialPrice.toStringAsFixed(2));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsed = double.tryParse(_controller.text);
    if (parsed == null || parsed < 0) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل السعر'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: const InputDecoration(
          labelText: 'السعر الجديد',
          suffixText: 'ج.م',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('حفظ')),
      ],
    );
  }
}
