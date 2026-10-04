import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

class ReturnItemSelector extends StatefulWidget {
  final InvoiceItemRow item;
  final int quantity;
  final int returnedQuantity;
  final ValueChanged<int> onChanged;

  const ReturnItemSelector({
    super.key,
    required this.item,
    required this.quantity,
    required this.returnedQuantity,
    required this.onChanged,
  });

  @override
  State<ReturnItemSelector> createState() => _ReturnItemSelectorState();
}

class _ReturnItemSelectorState extends State<ReturnItemSelector> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  int get _remaining => widget.item.quantity - widget.returnedQuantity;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ReturnItemSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) _syncText();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    } else if (_controller.text.isEmpty) {
      _setText('${widget.quantity}');
    }
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncText() {
    if (_focusNode.hasFocus &&
        _controller.text.isEmpty &&
        widget.quantity == 0) {
      return;
    }
    final text = '${widget.quantity}';
    if (_controller.text != text) _setText(text);
  }

  void _onTyped(String value) {
    final parsed = int.tryParse(value) ?? 0;
    final max = _remaining < 0 ? 0 : _remaining;
    final clamped = parsed > max ? max : parsed;
    if (clamped != parsed) _setText('$clamped');
    if (clamped != widget.quantity) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;
    final quantity = widget.quantity;
    final remainingQuantity = _remaining;
    final isFullyReturned = remainingQuantity <= 0;
    final iconColor = colors.text;
    final disabledIconColor = colors.textMuted.withOpacity(0.4);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:
            isFullyReturned ? colors.surface.withOpacity(0.6) : colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: isFullyReturned
                ? colors.border.withOpacity(0.5)
                : colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.cairoMedium16.copyWith(
                      color: isFullyReturned ? colors.textMuted : colors.text,
                      fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'المباع: ${item.quantity} — السعر: ${item.unitPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
                Text(
                  'مرتجع سابقاً: ${widget.returnedQuantity} — المتاح: $remainingQuantity',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: remainingQuantity > 0
                          ? colors.primary
                          : AppColors.statusNotReached,
                      fontSize: 10.sp),
                ),
                if (isFullyReturned)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'تم إرجاع هذا المنتج بالكامل',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: AppColors.statusNotReached, fontSize: 10.sp),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: (!isFullyReturned && quantity > 0)
                ? () => widget.onChanged(quantity - 1)
                : null,
            color: iconColor,
            disabledColor: disabledIconColor,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 52.w,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isFullyReturned,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _onTyped,
              style: AppTextStyles.cairoMedium16.copyWith(
                  color: isFullyReturned ? colors.textMuted : colors.text,
                  fontSize: 13.sp),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.background,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: colors.border),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: (!isFullyReturned && quantity < remainingQuantity)
                ? () => widget.onChanged(quantity + 1)
                : null,
            color: iconColor,
            disabledColor: disabledIconColor,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}