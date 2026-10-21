import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

typedef HistoricalLineInput = ({int quantity, double price});

class HistoricalLineDialog extends StatefulWidget {
  final String productName;
  final int quantity;
  final double unitPrice;

  const HistoricalLineDialog({
    super.key,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  @override
  State<HistoricalLineDialog> createState() => _HistoricalLineDialogState();
}

class _HistoricalLineDialogState extends State<HistoricalLineDialog> {
  late final TextEditingController _quantityController =
      TextEditingController(text: '${widget.quantity}');
  late final TextEditingController _priceController =
      TextEditingController(text: widget.unitPrice.toStringAsFixed(2));

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (quantity <= 0 || price < 0) return;
    Navigator.pop<HistoricalLineInput>(
        context, (quantity: quantity, price: price));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.productName,
        style: AppTextStyles.cairoMedium16.copyWith(fontSize: 14.sp),
      ),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'السعر'),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
