import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_item_model.dart';
import 'nav_items.dart';

class AppSideNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppSideNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 28.h),
            for (int i = 0; i < appNavItems.length; i++)
              _SideNavItem(
                item: appNavItems[i],
                isSelected: i == selectedIndex,
                onTap: () => onTabChange(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 22.sp,
                  color: isSelected ? Colors.white : AppColors.navInactive,
                ),
                SizedBox(height: 6.h),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairoRegular14.copyWith(
                    color: isSelected ? Colors.white : AppColors.navInactive,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
