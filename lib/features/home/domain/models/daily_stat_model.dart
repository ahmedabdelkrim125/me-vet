import 'package:flutter/material.dart';

class DailyStatModel {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DailyStatModel({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
