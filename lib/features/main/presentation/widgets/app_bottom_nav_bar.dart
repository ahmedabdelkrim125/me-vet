// import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
// import 'package:flutter/material.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'nav_item_model.dart';
// import 'nav_items.dart';

// /// ناف بار سفلي بتأثير Liquid Glass حقيقي (blur + إضاءة حواف) من مكتبة
// /// cupertino_liquid_glass، مبني حوالين نفس عناصر التابات والأيقونات
// /// (HugeIcons) اللي كانت موجودة قبل كده من غير أي تغيير في الـ navigation.
// ///
// /// ليه مش استخدمنا CupertinoLiquidGlassBottomBar الجاهزة من الباكدج؟
// /// لأنها بتتوقع أيقونات IconData عادية (زي CupertinoIcons.house)، وأيقونات
// /// التطبيق كلها HugeIcons (شكل بيانات مختلف تمامًا) — واستخدامها كان
// /// هيبقى معناه تغيير الأيقونات، وده ممنوع صراحةً. فبدل كده استخدمنا
// /// الـ wrapper الأساسي (CupertinoLiquidGlass) حوالين نفس الـ Row بتاعنا.
// ///
// /// الإعدادات (آخر عنصر في appNavItems) اتقلعت من جوه الـ bar وبقت
// /// LiquidGlassDetachedButton منفصلة — هي الحاجة الوحيدة اللي بيدعمها
// /// الباكدج بمرونة كاملة (child: Widget) فعرفنا نحطلها الأيقونة زي ما هي.
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
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final glassTheme =
//         isDark ? LiquidGlassThemeData.dark() : LiquidGlassThemeData.light();

//     final barItems = appNavItems.sublist(0, appNavItems.length - 1);
//     final settingsItem = appNavItems.last;
//     final settingsIndex = appNavItems.length - 1;

//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: CupertinoLiquidGlass(
//                 theme: glassTheme,
//                 borderRadius: BorderRadius.circular(34.r),
//                 padding: EdgeInsets.symmetric(horizontal: 6.w),
//                 height: 72.h,

//                 blurSigma: 30,
//                 tintOpacity: isDark ? 0.55 : 0.42,
//                 borderWidth: 1.4,
//                 edgeLightColor: isDark
//                     ? const Color(0x59FFFFFF)
//                     : const Color(0x99FFFFFF),
//                 child: Row(
//                   children: [
//                     for (int i = 0; i < barItems.length; i++)
//                       Expanded(
//                         child: _NavTab(
//                           item: barItems[i],
//                           isSelected: i == selectedIndex,
//                           onTap: () => onTabChange(i),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(width: 10.w),
//             _DetachedSettingsButton(
//               item: settingsItem,
//               isSelected: selectedIndex == settingsIndex,
//               theme: glassTheme,
//               onTap: () => onTabChange(settingsIndex),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NavTab extends StatelessWidget {
//   final NavItemModel item;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _NavTab({
//     required this.item,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final color = isSelected ? colors.primary : colors.textMuted;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20.r),
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 320),
//           curve: Curves.easeOutBack,
//           margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
//           padding: EdgeInsets.symmetric(horizontal: 10.w),
//           decoration: BoxDecoration(
//             color: isSelected ? colors.primary.withOpacity(0.32) : null,
//             borderRadius: BorderRadius.circular(26.r),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedScale(
//                 duration: const Duration(milliseconds: 320),
//                 curve: Curves.easeOutBack,
//                 scale: isSelected ? 1.08 : 1.0,
//                 child: HugeIcon(icon: item.icon, size: 19.sp, color: color),
//               ),
//               SizedBox(width: 5.w),
//               // Flexible + FittedBox: النص يتصغّر لوحده لو المساحة ضيقة
//               // بدل ما يتقطع بـ "..." بدل ما يتقطع.
//               Flexible(
//                 child: FittedBox(
//                   fit: BoxFit.scaleDown,
//                   alignment: Alignment.center,
//                   child: Text(
//                     item.label,
//                     maxLines: 1,
//                     style: AppTextStyles.cairoRegular14.copyWith(
//                       fontSize: 11.sp,
//                       color: color,
//                       fontWeight:
//                           isSelected ? FontWeight.w700 : FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DetachedSettingsButton extends StatelessWidget {
//   final NavItemModel item;
//   final bool isSelected;
//   final LiquidGlassThemeData theme;
//   final VoidCallback onTap;

//   const _DetachedSettingsButton({
//     required this.item,
//     required this.isSelected,
//     required this.theme,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final color = isSelected ? colors.primary : colors.textMuted;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         LiquidGlassDetachedButton(
//           size: 52,
//           theme: theme,
//           semanticLabel: item.label,
//           onTap: onTap,
//           child: HugeIcon(icon: item.icon, size: 22.sp, color: color),
//         ),
//         SizedBox(height: 4.h),
//         Text(
//           item.label,
//           style: AppTextStyles.cairoRegular14.copyWith(
//             fontSize: 10.sp,
//             color: color,
//             fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
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
    final colors = context.colors;
    final barItems = appNavItems.sublist(0, appNavItems.length - 1);
    final settingsIndex = appNavItems.length - 1;
    final clampedIndex = selectedIndex >= barItems.length ? 0 : selectedIndex;

    return CurvedNavigationBar(
      index: clampedIndex,
      height: 60.h,
      backgroundColor: colors.background,
      color: colors.surface,
      buttonBackgroundColor: colors.primary,
      animationCurve: Curves.easeOutBack,
      animationDuration: const Duration(milliseconds: 400),
      onTap: (i) {
        if (selectedIndex == settingsIndex) return;
        onTabChange(i);
      },
      items: [
        for (int i = 0; i < barItems.length; i++)
          HugeIcon(
            icon: barItems[i].icon,
            size: 22.sp,
            color: i == clampedIndex && selectedIndex != settingsIndex
                ? Colors.white
                : colors.textMuted,
          ),
      ],
    );
  }
}
