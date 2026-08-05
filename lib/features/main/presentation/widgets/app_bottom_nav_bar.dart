import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreenDark.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: GNav(
            gap: 6.w,
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            curve: Curves.easeOutExpo,
            duration: const Duration(milliseconds: 400),
            color: AppColors.navInactive,
            activeColor: Colors.white,
            iconSize: 22.sp,
            tabBackgroundColor: AppColors.primaryGreen,
            tabBorderRadius: 18.r,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            tabs: appNavItems
                .map(
                  (item) => GButton(
                    icon: item.icon,
                    text: item.label,
                    textStyle: AppTextStyles.cairoMedium16.copyWith(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
