import 'package:flutter/material.dart';

class EditReasonDialog extends StatefulWidget {
  const EditReasonDialog({super.key});

  @override
  State<EditReasonDialog> createState() => _EditReasonDialogState();
}

class _EditReasonDialogState extends State<EditReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('سبب تعديل الفاتورة'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'السبب',
          hintText: 'مثال: تعديل الكمية بعد مراجعة العميل',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('متابعة')),
      ],
    );
  }
}
