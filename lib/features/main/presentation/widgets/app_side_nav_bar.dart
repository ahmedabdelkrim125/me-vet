import 'dart:ui';

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
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.subtleShadow,
            blurRadius: 24,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SideNavHeader(onCollapse: onCollapse),
            SizedBox(height: 14.h),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: colors.background.withOpacity(0.74),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(color: colors.border),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
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
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _SideNavTile(
              item: settingsItem,
              isSelected: selectedIndex == settingsIndex,
              onTap: () => onTabChange(settingsIndex),
              compact: true,
            ),
            const SideNavUserCard(),
          ],
        ),
      ),
    );
  }
}

class _SideNavHeader extends StatelessWidget {
  final VoidCallback onCollapse;

  const _SideNavHeader({required this.onCollapse});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'إخفاء القائمة',
            child: Material(
              color: colors.surface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCollapse,
                child: Padding(
                  padding: EdgeInsets.all(9.w),
                  child: Icon(
                    Icons.menu_open_rounded,
                    color: colors.text,
                    size: 21.sp,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Image.asset(AppImages.logoSplash, height: 36.h),
        ],
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _SideNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = isSelected ? colors.primary : colors.textMuted;
    final textColor = isSelected ? colors.text : colors.textMuted;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 8.h),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(minHeight: compact ? 50.h : 56.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.surface
                    : colors.surface.withOpacity(compact ? 0.54 : 0),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isSelected
                      ? colors.primary.withOpacity(0.22)
                      : Colors.transparent,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.subtleShadow,
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 4.w,
                    height: isSelected ? 30.h : 18.h,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Text(
                      item.label,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoMedium16.copyWith(
                        fontSize: compact ? 12.sp : 13.sp,
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withOpacity(0.12)
                          : colors.background.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: item.icon,
                        size: 20.sp,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
