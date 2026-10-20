import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_level.dart';

class InventoryStatRow extends StatelessWidget {
  final int total;
  final int available;
  final int low;
  final int outOfStock;
  final StockLevel selected;
  final ValueChanged<StockLevel> onSelect;

  const InventoryStatRow({
    super.key,
    required this.total,
    required this.available,
    required this.low,
    required this.outOfStock,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        level: StockLevel.all,
        label: 'إجمالي الأصناف',
        value: total,
        color: context.colors.primary
      ),
      (
        level: StockLevel.available,
        label: 'متوفر',
        value: available,
        color: context.colors.primary
      ),
      (
        level: StockLevel.low,
        label: 'منخفض',
        value: low,
        color: context.colors.statOrange
      ),
      (
        level: StockLevel.out,
        label: 'نفد',
        value: outOfStock,
        color: context.colors.statusNotReached
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => onSelect(
                  selected == stats[i].level && stats[i].level != StockLevel.all
                      ? StockLevel.all
                      : stats[i].level,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: selected == stats[i].level
                        ? stats[i].color.withOpacity(0.12)
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selected == stats[i].level
                          ? stats[i].color
                          : context.colors.border,
                      width: selected == stats[i].level ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('${stats[i].value}',
                          style: AppTextStyles.cairoBold18.copyWith(
                              color: stats[i].color, fontSize: 16.sp)),
                      SizedBox(height: 4.h),
                      Text(stats[i].label,
                          style: AppTextStyles.almaraiRegular14.copyWith(
                              color: context.colors.textMuted, fontSize: 9.sp)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i != stats.length - 1) SizedBox(width: 8.w),
        ],
      ],
    );
  }
}
