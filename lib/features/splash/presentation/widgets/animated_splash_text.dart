import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme_extension.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_extension.dart';

class AnimatedSplashText extends StatelessWidget {
  final String text;
  final Animation<double> entranceAnimation;

  const AnimatedSplashText({
    super.key,
    required this.text,
    required this.entranceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');

    return AnimatedBuilder(
      animation: entranceAnimation,
      builder: (context, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: List.generate(words.length, (index) {
            final start = (0.4 + index * 0.08).clamp(0.0, 1.0);
            final end = (start + 0.35).clamp(0.0, 1.0);
            final wordAnimation = CurvedAnimation(
              parent: entranceAnimation,
              curve: Interval(start, end, curve: Curves.easeOut),
            );
            final opacity = wordAnimation.value.clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - opacity)),
                child: Text(
                  words[index],
                  style: AppTextStyles.wessamBold24black.copyWith(
                    fontSize: 30.sp,
                    color: context.colors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
