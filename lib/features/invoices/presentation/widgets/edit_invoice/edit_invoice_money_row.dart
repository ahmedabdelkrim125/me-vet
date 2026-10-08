import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class EditInvoiceMoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const EditInvoiceMoneyRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: colors.textMuted,
            fontSize: 11.sp,
          ),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(2)} ج.م',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: highlight ? colors.primary : colors.text,
            fontSize: highlight ? 15.sp : 12.sp,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
