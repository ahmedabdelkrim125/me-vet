import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CustomerFilterBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  const CustomerFilterBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.counts,
  });

  static const List<String> _filters = ['الكل', 'نشط', 'يحتاج متابعة', 'متوقف'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
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
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filters[index],
                    style: AppTextStyles.cairoMedium16.copyWith(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textMuted,
                      fontSize: 12.sp,
                    ),
                  ),
                  if (counts[index] > 0) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        '${counts[index]}',
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: context.colors.primary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
