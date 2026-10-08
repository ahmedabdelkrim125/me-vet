import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CustomerSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const CustomerSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.colors.border),
      ),
      child: TextField(
        onChanged: onChanged,
        textAlign: TextAlign.right,
        style:
            AppTextStyles.cairoRegular14.copyWith(color: context.colors.text),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'ابحث بالاسم أو الهاتف أو الكود',
          hintStyle: AppTextStyles.almaraiRegular14.copyWith(
            color: context.colors.textMuted,
            fontSize: 12.sp,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(14.w),
            child: Icon(CupertinoIcons.search,
                size: 18.sp, color: context.colors.textMuted),
          ),
        ),
      ),
    );
  }
}
