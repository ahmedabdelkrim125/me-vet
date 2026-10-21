import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_quantity_field.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_step_button.dart';

class InvoiceLineItemTile extends StatefulWidget {
  final InvoiceLineItemModel item;
  final bool loadingCustomerPrices;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const InvoiceLineItemTile({
    super.key,
    required this.item,
    required this.loadingCustomerPrices,
    required this.onPriceChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<InvoiceLineItemTile> createState() => _InvoiceLineItemTileState();
}

class _InvoiceLineItemTileState extends State<InvoiceLineItemTile> {
  late final TextEditingController _priceController;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
    _priceFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant InvoiceLineItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_priceFocus.hasFocus) return;
    final parsed = double.tryParse(_priceController.text);
    final price = widget.item.unitPrice;
    if (parsed == null || (parsed - price).abs() >= 0.005) {
      _priceController.text = price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;
    final loadingCustomerPrices = widget.loadingCustomerPrices;
    final onPriceChanged = widget.onPriceChanged;
    final onQuantityChanged = widget.onQuantityChanged;
    final onRemove = widget.onRemove;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Material(
            color: colors.statusNotReached.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Icon(Icons.close_rounded,
                    size: 14.sp, color: colors.statusNotReached),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 12.5.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  item.previousCustomerPrice == null
                      ? 'سعر الأساسي: ${formatMoney(item.product.price)}'
                      : 'السعر السابق للعميل: ${formatMoney(item.previousCustomerPrice!)}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.5.sp),
                ),
                SizedBox(height: 5.h),
                SizedBox(
                  height: 40.h,
                  width: 150.w,
                  child: TextField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    enabled: !loadingCustomerPrices,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 13.sp),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null && price >= 0) onPriceChanged(price);
                    },
                    decoration: InputDecoration(
                      labelText: 'سعر البيع',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 10.h),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          InvoiceStepButton(
              icon: Icons.remove_rounded,
              onTap: () => onQuantityChanged(item.quantity - 1)),
          InvoiceQuantityField(
            quantity: item.quantity,
            onQuantityChanged: onQuantityChanged,
          ),
          InvoiceStepButton(
              icon: Icons.add_rounded,
              onTap: () => onQuantityChanged(item.quantity + 1)),
          SizedBox(width: 10.w),
          SizedBox(
            width: 62.w,
            child: Text(
              formatMoney(item.total),
              textAlign: TextAlign.end,
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
