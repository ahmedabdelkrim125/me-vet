import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/extensions.dart';
import '../../auth/data/repositories/auth_repository_impl.dart';
import '../../auth/domain/models/user_profile.dart';
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

    Future.delayed(const Duration(milliseconds: 2800), _redirect);
  }

  Future<void> _redirect() async {
    if (!mounted) return;

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) {
      context.pushReplacementNamed(Routes.loginTypeScreen);
      return;
    }

    final profile =
        await AuthRepositoryImpl(Supabase.instance.client).getCurrentUser();
    if (!mounted) return;

    if (profile == null) {
      context.pushReplacementNamed(Routes.loginTypeScreen);
    } else if (profile.role == UserRole.owner) {
      context.pushReplacementNamed(Routes.ownerDashboard);
    } else {
      context.pushReplacementNamed(Routes.mainScreen);
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
