import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/product_category.dart';

class InventoryCategoryFilter extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onChanged;

  const InventoryCategoryFilter(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
              label: 'الكل',
              isSelected: selected == null,
              onTap: () => onChanged(null)),
          SizedBox(width: 8.w),
          for (final category in ProductCategory.values) ...[
            _Chip(
                label: category.label,
                isSelected: selected == category,
                onTap: () => onChanged(category)),
            if (category != ProductCategory.values.last) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withOpacity(0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color:
                  isSelected ? context.colors.primary : context.colors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.cairoMedium16.copyWith(
            color:
                isSelected ? context.colors.primary : context.colors.textMuted,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
