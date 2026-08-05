import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';

import '../../../core/utils/extensions.dart';
import 'widgets/splash_background.dart';
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

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.pushReplacementNamed(Routes.mainScreen);
    });
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SplashBackground(),
            SplashBody(
              entranceController: entranceController,
              loopController: loopController,
            ),
          ],
        ),
      ),
    );
  }
}
