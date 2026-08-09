import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../../../core/const/app_images.dart';
import '../../../../core/theme/app_color_scheme_extension.dart';
import '../../../../core/theme/theme_controller.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

        return GestureDetector(
          onTap: () => ThemeController.instance.toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            width: 84.w,
            height: 44.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              gradient: LinearGradient(
                colors: isDark
                    ? [context.colors.surface, context.colors.background]
                    : [
                        context.colors.primary.withOpacity(0.4),
                        context.colors.primary
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark ? Colors.black : Colors.orange).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  alignment:
                      isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: Tween<double>(begin: 0.5, end: 1)
                            .animate(animation),
                        child: ScaleTransition(
                          scale: animation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(isDark),
                      width: 36.w,
                      height: 36.w,
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        isDark ? AppImages.moon : AppImages.sun,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
