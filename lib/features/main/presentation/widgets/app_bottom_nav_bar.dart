// import 'package:flutter/material.dart';
// import 'package:google_nav_bar/google_nav_bar.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_colors.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'nav_items.dart';

// class AppBottomNavBar extends StatelessWidget {
//   final int selectedIndex;
//   final ValueChanged<int> onTabChange;

//   const AppBottomNavBar({
//     super.key,
//     required this.selectedIndex,
//     required this.onTabChange,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primaryGreenDark.withOpacity(0.10),
//             blurRadius: 24,
//             offset: const Offset(0, -6),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
//           child: GNav(
//             gap: 6.w,
//             selectedIndex: selectedIndex,
//             onTabChange: onTabChange,
//             curve: Curves.easeOutExpo,
//             duration: const Duration(milliseconds: 400),
//             color: AppColors.navInactive,
//             activeColor: Colors.white,
//             iconSize: 22.sp,
//             tabBackgroundColor: context.colors.primary,
//             tabBorderRadius: 18.r,
//             padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
//             tabs: List.generate(appNavItems.length, (index) {
//               final item = appNavItems[index];
//               final isSelected = index == selectedIndex;

//               return GButton(
//                 icon: Icons.circle_outlined,
//                 leading: HugeIcon(
//                   icon: item.icon,
//                   size: 22.sp,
//                   color: isSelected ? Colors.white : context.colors.textMuted,
//                 ),
//                 text: item.label,
//                 textStyle: AppTextStyles.cairoMedium16.copyWith(
//                   color: Colors.white,
//                   fontSize: 13.sp,
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
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

  Widget _buildIcon(BuildContext context, dynamic icon, int index) {
    final isSelected = selectedIndex == index;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        HugeIcon(
          icon: icon,
          color: isSelected ? context.colors.primary : context.colors.textMuted,
          size: 24.r,
        ),
        if (isSelected)
          Positioned(
            top: -2.h,
            right: -3.w,
            child: Container(
              width: 7.r,
              height: 7.r,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
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
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTabChange,
            type: BottomNavigationBarType.fixed,
            backgroundColor: context.colors.surface,
            selectedItemColor: context.colors.primary,
            unselectedItemColor: context.colors.textMuted,
            selectedLabelStyle: AppTextStyles.cairoMedium16.copyWith(
              color: context.colors.primary,
              fontSize: 13.sp,
            ),
            unselectedLabelStyle: AppTextStyles.cairoMedium16.copyWith(
              color: context.colors.textMuted,
              fontSize: 13.sp,
            ),
            elevation: 0,
            items: List.generate(appNavItems.length, (index) {
              final item = appNavItems[index];

              return BottomNavigationBarItem(
                icon: _buildIcon(context, item.icon, index),
                label: item.label,
              );
            }),
          ),
        ),
      ),
    );
  }
}
