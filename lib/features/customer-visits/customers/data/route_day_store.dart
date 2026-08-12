import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/route_stop_model.dart';
import '../domain/models/visit_status.dart';

/// المصدر الوحيد للحقيقة لـ "خط اليوم" — بيتشارك بين تبويب العملاء
/// (RouteView) وداشبورد الرئيسية (HomeScreen) عشان الاتنين يفضلوا متزامنين.
class RouteDayStore {
  RouteDayStore._();
  static final RouteDayStore instance = RouteDayStore._();

  static const _stopsKey = 'route_day_stops';

  final ValueNotifier<List<RouteStopModel>> stopsNotifier =
  ValueNotifier<List<RouteStopModel>>(<RouteStopModel>[]);

  bool _initialized = false;

  List<RouteStopModel> get stops => stopsNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stopsKey);
    if (raw != null && raw.isNotEmpty) {
      final list = (jsonDecode(raw) as List)
          .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
          .toList();
      stopsNotifier.value = list;
    }
    _initialized = true;
  }

  Future<void> setStops(List<RouteStopModel> newStops) async {
    stopsNotifier.value = List<RouteStopModel>.from(newStops);
    await _persist();
  }

  Future<void> updateStop(RouteStopModel updated) async {
    final list = List<RouteStopModel>.from(stops);
    final index = list.indexWhere((s) => s.customerId == updated.customerId);
    if (index == -1) return;
    list[index] = updated;
    stopsNotifier.value = list;
    await _persist();
  }

  Future<void> removeStop(String customerId) async {
    final list = List<RouteStopModel>.from(stops)
      ..removeWhere((s) => s.customerId == customerId);
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(order: i + 1);
    }
    stopsNotifier.value = list;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stops.map((s) => s.toJson()).toList());
    await prefs.setString(_stopsKey, encoded);
  }
}