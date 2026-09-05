import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/customer_transaction.dart';

class TransactionTypeBadge extends StatelessWidget {
  final CustomerTransactionType type;

  const TransactionTypeBadge({super.key, required this.type});

  Color _colorFor(AppColorScheme colors) {
    switch (type) {
      case CustomerTransactionType.invoice:
        return colors.statOrange;
      case CustomerTransactionType.payment:
        return colors.primary;
      case CustomerTransactionType.salesReturn:
      case CustomerTransactionType.refund:
        return colors.statusNotReached;
      case CustomerTransactionType.adjustment:
        return colors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _colorFor(colors);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        type.label,
        style: AppTextStyles.cairoMedium16.copyWith(color: color, fontSize: 10.sp),
      ),
    );
  }
}