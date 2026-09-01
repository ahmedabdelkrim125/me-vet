import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import 'nav_item_model.dart';
import 'nav_items.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barItems = appNavItems.sublist(0, appNavItems.length - 1);
    final settingsIndex = appNavItems.length - 1;
    final hasActiveTab = selectedIndex >= 0 && selectedIndex < barItems.length;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: colors.border.withOpacity(0.9)),
              boxShadow: [
                BoxShadow(
                  color: colors.subtleShadow,
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < barItems.length; i++)
                  Expanded(
                    child: _MobileNavTab(
                      item: barItems[i],
                      isSelected: hasActiveTab && selectedIndex == i,
                      onTap: () => onTabChange(i),
                    ),
                  ),
                SizedBox(width: 54.w),
                Semantics(
                  label: appNavItems[settingsIndex].label,
                  child: SizedBox(width: 1.w),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavTab extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileNavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = colors.primary;
    final inactiveColor = colors.textMuted;

    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 52.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 36.w : 28.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: item.icon,
                      size: 20.sp,
                      color: isSelected ? Colors.white : inactiveColor,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isSelected
                      ? Text(
                          item.label,
                          key: const ValueKey('label'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.cairoRegular14.copyWith(
                            fontSize: 9.sp,
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('dot'),
                          height: 9.h,
                          child: Center(
                            child: Container(
                              width: 3.5.w,
                              height: 3.5.w,
                              decoration: BoxDecoration(
                                color: inactiveColor.withOpacity(0.32),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
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
