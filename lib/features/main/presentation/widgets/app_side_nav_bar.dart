import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_item_model.dart';
import 'nav_items.dart';
import 'side_nav_user_card.dart';

class AppSideNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;
  final VoidCallback onCollapse;

  const AppSideNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barItems = appNavItems.sublist(0, appNavItems.length - 1);
    final settingsItem = appNavItems.last;
    final settingsIndex = appNavItems.length - 1;

    return Container(
      width: 240.w,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onCollapse,
                    icon: Icon(Icons.menu_rounded,
                        color: colors.text, size: 22.sp),
                    tooltip: 'إخفاء القائمة',
                  ),
                  const Spacer(),
                  Image.asset(AppImages.logoSplash, height: 34.h),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                children: [
                  for (int i = 0; i < barItems.length; i++)
                    _SideNavTile(
                      item: barItems[i],
                      isSelected: i == selectedIndex,
                      onTap: () => onTabChange(i),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: _SideNavTile(
                item: settingsItem,
                isSelected: selectedIndex == settingsIndex,
                onTap: () => onTabChange(settingsIndex),
              ),
            ),
            SizedBox(height: 8.h),
            const SideNavUserCard(),
          ],
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isSelected ? Colors.white : colors.text;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: isSelected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.cairoMedium16.copyWith(
                      fontSize: 14.sp,
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                HugeIcon(icon: item.icon, size: 20.sp, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
