import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InventoryStatRow extends StatelessWidget {
  final int total;
  final int available;
  final int low;
  final int outOfStock;

  const InventoryStatRow({
    super.key,
    required this.total,
    required this.available,
    required this.low,
    required this.outOfStock,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (label: 'إجمالي الأصناف', value: total, color: context.colors.primary),
      (label: 'متوفر', value: available, color: context.colors.primary),
      (label: 'منخفض', value: low, color: context.colors.statOrange),
      (label: 'نفد', value: outOfStock, color: context.colors.statusNotReached),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  Text('${stats[i].value}',
                      style: AppTextStyles.cairoBold18
                          .copyWith(color: stats[i].color, fontSize: 16.sp)),
                  SizedBox(height: 4.h),
                  Text(stats[i].label,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: context.colors.textMuted, fontSize: 9.sp)),
                ],
              ),
            ),
          ),
          if (i != stats.length - 1) SizedBox(width: 8.w),
        ],
      ],
    );
  }
}
