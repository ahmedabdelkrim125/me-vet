import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';

class DockSurface extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  final Color? fillColor;
  final Widget child;

  const DockSurface({
    super.key,
    required this.height,
    required this.radius,
    required this.child,
    this.width,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // A black shadow on a dark background just looks like a dirty smudge
        // around the dock, so in dark mode we rely on the border instead.
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colors.subtleShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  fillColor ?? colors.surface.withOpacity(isDark ? 0.97 : 0.92),
              borderRadius: borderRadius,
              border: Border.all(color: colors.border.withOpacity(0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
