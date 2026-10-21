import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceQuantityField extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const InvoiceQuantityField({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  State<InvoiceQuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<InvoiceQuantityField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
  }

  @override
  void didUpdateWidget(covariant InvoiceQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsed = int.tryParse(_controller.text);
    if (parsed != widget.quantity) {
      _controller.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 46.w,
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: AppTextStyles.cairoMedium16
            .copyWith(color: colors.text, fontSize: 12.sp),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final qty = int.tryParse(value.trim());
          if (qty != null && qty >= 0) {
            widget.onQuantityChanged(qty);
          }
        },
      ),
    );
  }
}
