import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        textAlign: TextAlign.right,
        style: AppTextStyles.cairoRegular14.copyWith(color: AppColors.primary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'ابحث بالاسم أو الهاتف أو الكود',
          hintStyle: AppTextStyles.almaraiRegular14.copyWith(
            color: AppColors.navInactive,
            fontSize: 12.sp,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(14.w),
            child: Icon(CupertinoIcons.search,
                size: 18.sp, color: AppColors.navInactive),
          ),
        ),
      ),
    );
  }
}
