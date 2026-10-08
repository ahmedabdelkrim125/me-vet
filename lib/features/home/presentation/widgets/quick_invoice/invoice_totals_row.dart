import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceTotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const InvoiceTotalsRow({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp)),
        SizedBox(width: 8.w),
        Expanded(
            child: Text(value,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: muted ? colors.statOrange : colors.text,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.end)),
      ],
    );
  }
}
