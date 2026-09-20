import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';

/// Shared "glass" surface used by the floating mobile dock
/// (the navigation pill and the detached settings button).
///
/// The shadow lives on the outer container so it is not clipped by the
/// rounded [ClipRRect] that blurs whatever is behind the dock.
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
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
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
              color: fillColor ?? colors.surface.withOpacity(0.92),
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
