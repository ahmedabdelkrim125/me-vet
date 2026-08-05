import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_item_model.dart';

class TabPlaceholder extends StatelessWidget {
  final NavItemModel item;

  const TabPlaceholder({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 64.sp,
            color: AppColors.primaryGreen.withOpacity(0.35),
          ),
          SizedBox(height: 16.h),
          Text(
            item.label,
            style: AppTextStyles.cairoBold18.copyWith(
              color: AppColors.primaryGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}
