import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoicePagination extends StatelessWidget {
  final int itemCount;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const InvoicePagination({
    super.key,
        required this.itemCount,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pageCount = (itemCount / 15).ceil();
    final start = (currentPage - 1) * 15 + 1;
    final end = (currentPage * 15).clamp(0, itemCount);
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Column(
        children: [
          Text(
            'الأصناف $start - $end من $itemCount',
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: colors.textMuted,
              fontSize: 11.sp,
            ),
          ),
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  child: const Text('السابق'),
                ),
                for (var page = 1; page <= pageCount; page++)
                  TextButton(
                    onPressed:
                        page == currentPage ? null : () => onPageChanged(page),
                    child: Text('$page'),
                  ),
                TextButton(
                  onPressed: currentPage < pageCount
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  child: const Text('التالي'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
