import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditQuantityDialog extends StatefulWidget {
  final int quantity;

  const EditQuantityDialog({super.key, required this.quantity});

  @override
  State<EditQuantityDialog> createState() => _EditQuantityDialogState();
}

class _EditQuantityDialogState extends State<EditQuantityDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.quantity}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed <= 0) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الكمية'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'الكمية الجديدة'),
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
