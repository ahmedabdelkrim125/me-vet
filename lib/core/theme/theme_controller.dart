import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'isDarkMode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefsKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    await setDark(themeMode.value != ThemeMode.dark);
  }

  Future<void> setDark(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isDark);
  }
}
