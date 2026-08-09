// import 'package:flutter/material.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:mivet_app/core/theme/app_colors.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'nav_item_model.dart';
// import 'nav_items.dart';

// class AppSideNavBar extends StatelessWidget {
//   final int selectedIndex;
//   final ValueChanged<int> onTabChange;

//   const AppSideNavBar({
//     super.key,
//     required this.selectedIndex,
//     required this.onTabChange,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       width: 100.w,
//       color: theme.cardTheme.color,
//       child: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             SizedBox(height: 28.h),
//             for (int i = 0; i < appNavItems.length; i++)
//               _SideNavItem(
//                 item: appNavItems[i],
//                 isSelected: i == selectedIndex,
//                 onTap: () => onTabChange(i),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SideNavItem extends StatelessWidget {
//   final NavItemModel item;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _SideNavItem({
//     required this.item,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final inactiveColor =
//         Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.navInactive;

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(14.r),
//           onTap: onTap,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(vertical: 12.h),
//             decoration: BoxDecoration(
//               color: isSelected ? AppColors.primaryGreen : Colors.transparent,
//               borderRadius: BorderRadius.circular(14.r),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 HugeIcon(
//                   icon: item.icon,
//                   size: 22.sp,
//                   color: isSelected ? Colors.white : inactiveColor,
//                 ),
//                 SizedBox(height: 6.h),
//                 Text(
//                   item.label,
//                   textAlign: TextAlign.center,
//                   style: AppTextStyles.cairoRegular14.copyWith(
//                     color: isSelected ? Colors.white : inactiveColor,
//                     fontSize: 11.sp,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_items.dart';

class AppSideNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppSideNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  State<AppSideNavBar> createState() => _AppSideNavBarState();
}

class _AppSideNavBarState extends State<AppSideNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _indicatorAnimation = AlwaysStoppedAnimation(widget.selectedIndex.toDouble());

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AppSideNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _indicatorAnimation = Tween<double>(
        begin: oldWidget.selectedIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(
        CurvedAnimation(parent: _indicatorController, curve: Curves.elasticOut),
      );
      _indicatorController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemHeight = 74.h;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final shimmer = _shimmerController.value;

              return Container(
                width: 92.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1 + shimmer * 2),
                    end: Alignment(1, 1 + shimmer * 2),
                    colors: [
                      context.colors.surface.withValues(alpha: 0.60),
                      context.colors.surface.withValues(alpha: 0.38),
                      context.colors.surface.withValues(alpha: 0.60),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreenDark.withValues(alpha: 0.20),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: AnimatedBuilder(
                animation: _indicatorAnimation,
                builder: (context, _) {
                  final animatedPos = _indicatorAnimation.value;
                  final distance = (widget.selectedIndex - animatedPos).abs();
                  final stretch = distance > 0.02
                      ? (1 - distance.clamp(0.0, 1.0))
                      : 0.0;

                  return Stack(
                    children: [
                      Positioned(
                        top: animatedPos * itemHeight + 6.h,
                        left: 8.w,
                        right: 8.w,
                        height: itemHeight - 12.h + (stretch * 16.h),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                context.colors.primary,
                                AppColors.primaryGreenDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary.withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: List.generate(appNavItems.length, (index) {
                          final item = appNavItems[index];
                          final isSelected = index == widget.selectedIndex;

                          return SizedBox(
                            height: itemHeight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20.r),
                                onTap: () => widget.onTabChange(index),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 450),
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.4,
                                              end: 1.0,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.elasticOut,
                                              ),
                                            ),
                                            child: RotationTransition(
                                              turns: Tween<double>(
                                                begin: 0.18,
                                                end: 0.0,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: HugeIcon(
                                          key: ValueKey(isSelected),
                                          icon: item.icon,
                                          size: 22.sp,
                                          color: isSelected
                                              ? Colors.white
                                              : context.colors.textMuted,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 300),
                                        style: AppTextStyles.cairoRegular14.copyWith(
                                          fontSize: 10.sp,
                                          color: isSelected
                                              ? Colors.white
                                              : context.colors.textMuted,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                        child: Text(
                                          item.label,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}