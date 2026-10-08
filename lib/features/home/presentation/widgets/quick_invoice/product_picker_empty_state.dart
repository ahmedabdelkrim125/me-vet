import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class ProductPickerEmptyState extends StatelessWidget {
  final bool hasStock;

  const ProductPickerEmptyState({super.key, required this.hasStock});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          hasStock
              ? 'مفيش منتج بالاسم ده في عربيتك'
              : 'مفيش منتجات في مخزون عربيتك دلوقتي',
          textAlign: TextAlign.center,
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 12.sp),
        ),
      ),
    );
  }
}
