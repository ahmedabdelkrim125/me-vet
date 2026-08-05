// features/splash/presentation/widgets/splash_background.dart
import 'package:flutter/material.dart';
import '../../../../core/const/app_images.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImages.splashBackground,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}