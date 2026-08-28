import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color statBlue;
  final Color statOrange;
  final Color statusNotReached;
  final Color subtleShadow;
  final Color heroBackground;

  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.statBlue,
    required this.statOrange,
    required this.statusNotReached,
    required this.subtleShadow,
    required this.heroBackground,
  });

  static const light = AppColorScheme(
    primary: AppColors.primaryGreen,
    secondary: AppColors.secondary,
    background: AppColors.backgroundLight,
    surface: Colors.white,
    text: AppColors.primary,
    textMuted: AppColors.navInactive,
    border: AppColors.cardBorder,
    statBlue: AppColors.statBlue,
    statOrange: AppColors.statOrange,
    statusNotReached: AppColors.statusNotReached,
    subtleShadow: Color(0x14000000),
    heroBackground: AppColors.primary,
  );

  static const dark = AppColorScheme(
    primary: Color(0xFF1E8A6E),
    secondary: Color(0xFF14506B),
    background: Color(0xFF141210),
    surface: Color(0xFF1C1917),
    text: Color(0xFFEDEDED),
    textMuted: Color(0xFF9A9A9A),
    border: Color(0xFF322E2A),
    statBlue: Color(0xFF5A93F5),
    statOrange: Color(0xFFF0A05C),
    statusNotReached: Color(0xFFE0473F),
    subtleShadow: Color(0x66000000),
    heroBackground: Color(0xFF1A3A5C),
  );

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? border,
    Color? statBlue,
    Color? statOrange,
    Color? statusNotReached,
    Color? subtleShadow,
    Color? heroBackground,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      statBlue: statBlue ?? this.statBlue,
      statOrange: statOrange ?? this.statOrange,
      statusNotReached: statusNotReached ?? this.statusNotReached,
      subtleShadow: subtleShadow ?? this.subtleShadow,
      heroBackground: heroBackground ?? this.heroBackground,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      statBlue: Color.lerp(statBlue, other.statBlue, t)!,
      statOrange: Color.lerp(statOrange, other.statOrange, t)!,
      statusNotReached:
          Color.lerp(statusNotReached, other.statusNotReached, t)!,
      subtleShadow: Color.lerp(subtleShadow, other.subtleShadow, t)!,
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
    );
  }
}

extension AppColorSchemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}
