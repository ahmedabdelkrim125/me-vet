import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import 'widgets/theme_toggle_switch.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      context.pushNamedAndRemoveUntil(
        Routes.loginTypeScreen,
        predicate: (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
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
            SizedBox(height: 14.h),
            Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(18.r),
              child: InkWell(
                onTap: () => _signOut(context),
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'تسجيل الخروج',
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: Colors.red,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}