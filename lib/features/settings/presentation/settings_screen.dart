import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../core/theme/theme_controller.dart';
import 'widgets/theme_toggle_switch.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text(
              'الإعدادات',
              style: AppTextStyles.cairoBold18.copyWith(
                color: context.colors.text,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مظهر التطبيق',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.text,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeController.instance.themeMode,
                          builder: (context, mode, _) {
                            return Text(
                              mode == ThemeMode.dark
                                  ? 'الوضع الليلي مفعّل'
                                  : 'الوضع النهاري مفعّل',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                color: context.colors.textMuted,
                                fontSize: 12.sp,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const ThemeToggleSwitch(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
