import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceRepChip extends StatelessWidget {
  final String name;
  const InvoiceRepChip({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.badge_outlined, size: 15.sp, color: colors.textMuted),
        SizedBox(width: 6.w),
        Flexible(
            child: Text('المندوب الحالي: $name',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: colors.textMuted,
                  fontSize: 12.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
