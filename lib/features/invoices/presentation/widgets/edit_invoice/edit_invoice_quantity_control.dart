import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_quantity_dialog.dart';

class EditInvoiceQuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final ValueChanged<int> onEditQuantity;

  const EditInvoiceQuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onEditQuantity,
  });

  Future<void> _promptQuantity(BuildContext context) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => EditQuantityDialog(quantity: quantity),
    );
    if (value != null) onEditQuantity(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          ),
          InkWell(
            onTap: () => _promptQuantity(context),
            child: SizedBox(
              width: 32.w,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: colors.primary,
                  fontSize: 13.sp,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          ),
        ],
      ),
    );
  }
}
