import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import 'detached_settings_button.dart';
import 'dock_surface.dart';
import 'nav_item_model.dart';
import 'nav_items.dart';

/// Floating bottom dock for phones.
///
/// Layout (RTL): [ navigation pill with 4 pages ]  [ detached settings ].
/// Every page always shows its icon AND its name.
///
/// This widget is meant to be placed in a [Stack] on top of the page body
/// (see `MainScreen`), NOT in `Scaffold.bottomNavigationBar`, so the pages
/// scroll underneath it and it really floats.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  static double get barHeight => 66.h;
  static double get _bottomMargin => 12.h;

  /// Total vertical space the dock occupies at the bottom of the screen
  /// (bar + floating margin + system safe area). Used by `MainScreen` to
  /// keep page content from hiding behind the dock.
  static double totalHeight(BuildContext context) =>
      barHeight + _bottomMargin + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final settingsIndex = appNavItems.length - 1;
    final barItems = appNavItems.sublist(0, settingsIndex);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        _bottomMargin + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: DockSurface(
              height: barHeight,
              radius: 28.r,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    for (int i = 0; i < barItems.length; i++)
                      Expanded(
                        child: _NavTab(
                          item: barItems[i],
                          isSelected: selectedIndex == i,
                          onTap: () => onTabChange(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          DetachedSettingsButton(
            height: barHeight,
            isSelected: selectedIndex == settingsIndex,
            onTap: () => onTabChange(settingsIndex),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isSelected ? colors.primary : colors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withOpacity(0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: HugeIcon(icon: item.icon, size: 22.sp, color: color),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cairoRegular14.copyWith(
                      fontSize: 10.sp,
                      height: 1.2,
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
