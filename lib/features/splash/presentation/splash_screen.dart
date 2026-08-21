import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/features/auth/data/auth_service.dart';

import '../../../core/utils/extensions.dart';
import 'widgets/splash_body.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController entranceController;
  late final AnimationController loopController;

  @override
  void initState() {
    super.initState();
    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;

    // التحقق من وجود session نشطة
    final hasSession = AuthService.instance.hasActiveSession;
    
    if (hasSession) {
      // يوجد session، الانتقال للصفحة الرئيسية
      context.pushReplacementNamed(Routes.mainScreen);
    } else {
      // لا يوجد session، الانتقال لشاشة تسجيل الدخول
      context.pushReplacementNamed(Routes.loginScreen);
    }
  }

  @override
  void dispose() {
    entranceController.dispose();
    loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SplashBody(
          entranceController: entranceController,
          loopController: loopController,
        ),
      ),
    );
  }
}
