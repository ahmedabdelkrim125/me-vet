import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'animated_logo.dart';
import 'animated_splash_text.dart';

class SplashBody extends StatelessWidget {
  final AnimationController entranceController;
  final AnimationController loopController;

  const SplashBody({
    super.key,
    required this.entranceController,
    required this.loopController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AdaptiveContentWrapper(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedLogo(entranceAnimation: entranceController),
            SizedBox(height: 24.h),
            AnimatedSplashText(
              text: 'إدارة وتوزيع الأدوية البيطرية',
              entranceAnimation: entranceController,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
