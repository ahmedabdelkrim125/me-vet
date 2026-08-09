import 'package:flutter/material.dart';

class DailyStatModel {
  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color color;
  final double trendPercent;

  const DailyStatModel({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendPercent,
  });
}
