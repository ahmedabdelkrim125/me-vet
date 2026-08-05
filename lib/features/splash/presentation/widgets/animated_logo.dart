import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../core/const/app_images.dart';

class AnimatedLogo extends StatelessWidget {
  final Animation<double> entranceAnimation;

  const AnimatedLogo({super.key, required this.entranceAnimation});

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = CurvedAnimation(
      parent: entranceAnimation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    final fadeAnimation = CurvedAnimation(
      parent: entranceAnimation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: entranceAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value.clamp(0, 1),
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        AppImages.logoSplash,
        width: 250.w,
        height: 250.h,
        fit: BoxFit.contain,
      ),
    );
  }
}
