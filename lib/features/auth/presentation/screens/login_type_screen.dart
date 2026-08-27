import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/extensions.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../widgets/login_header.dart';
import '../widgets/login_type_card.dart';

class LoginTypeScreen extends StatelessWidget {
  const LoginTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.adaptiveMaxContentWidth),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoginHeader(subtitle: 'اختار نوع الحساب للمتابعة'),
                  SizedBox(height: 40.h),
                  LoginTypeCard(
                    icon: Icons.badge_rounded,
                    title: 'تسجيل دخول مندوب',
                    subtitle: 'برقم الموبايل ورمز الـ PIN',
                    onTap: () => context.pushNamed(Routes.repLoginScreen),
                  ),
                  SizedBox(height: 14.h),
                  LoginTypeCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'تسجيل دخول الأونر',
                    subtitle: 'بالإيميل وكلمة المرور',
                    onTap: () => context.pushNamed(Routes.ownerLoginScreen),
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
