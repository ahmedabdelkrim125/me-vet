import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_customers_repository.dart';
import 'models/customer_model.dart';
import 'models/route_stop_model.dart';
import 'models/visit_status.dart';

class TodayRouteController {
  TodayRouteController._internal();

  static final TodayRouteController instance = TodayRouteController._internal();

  static const String _storageKey = 'today_route_stops';

  final ValueNotifier<List<RouteStopModel>> stopsNotifier =
      ValueNotifier<List<RouteStopModel>>(<RouteStopModel>[]);

  bool _initialized = false;

  List<RouteStopModel> get stops => stopsNotifier.value;

  List<String> get selectedCustomerIds =>
      stops.map((stop) => stop.customerId).toList();

  int get totalVisits => stops.length;

  int get completedVisits => stops.where(_countsAsCompleted).length;

  int get remainingVisits => totalVisits - completedVisits;

  Future<void> initialize() async {
    if (_initialized) return;

    await MockCustomersRepository.instance.initialize();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      stopsNotifier.value = <RouteStopModel>[];
      _initialized = true;
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final loadedStops = decoded
        .map((entry) => _stopFromJson(entry as Map<String, dynamic>))
        .where((stop) => _customerById(stop.customerId) != null)
        .toList();

    stopsNotifier.value = _renumber(loadedStops);
    _initialized = true;
  }

  Future<void> setSelectedCustomers(List<CustomerModel> customers) async {
    await initialize();

    final previousStatuses = {
      for (final stop in stops) stop.customerId: stop.status,
    };

    final nextStops = [
      for (int i = 0; i < customers.length; i++)
        RouteStopModel(
          customerId: customers[i].id,
          order: i + 1,
          customerName: customers[i].name,
          area: customers[i].area,
          status: previousStatuses[customers[i].id] ?? RouteVisitStatus.pending,
        ),
    ];

    await _setStops(nextStops);
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await initialize();
    if (selectedCustomerIds.contains(customer.id)) return;

    await _setStops([
      ...stops,
      RouteStopModel(
        customerId: customer.id,
        order: stops.length + 1,
        customerName: customer.name,
        area: customer.area,
        status: RouteVisitStatus.pending,
      ),
    ]);
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    await initialize();
    final nextStops = List<RouteStopModel>.from(stops);
    if (newIndex > oldIndex) newIndex -= 1;
    final stop = nextStops.removeAt(oldIndex);
    nextStops.insert(newIndex, stop);
    await _setStops(_renumber(nextStops));
  }

  Future<void> updateStatus(
    String customerId,
    RouteVisitStatus status,
  ) async {
    await initialize();
    final nextStops = [
      for (final stop in stops)
        stop.customerId == customerId ? stop.copyWith(status: status) : stop,
    ];
    await _setStops(nextStops);
  }

  Future<void> removeStop(String customerId) async {
    await initialize();
    await _setStops(
      _renumber(stops.where((stop) => stop.customerId != customerId).toList()),
    );
  }

  Future<void> _setStops(List<RouteStopModel> nextStops) async {
    stopsNotifier.value = List<RouteStopModel>.from(nextStops);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stops.map(_stopToJson).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Map<String, dynamic> _stopToJson(RouteStopModel stop) {
    return {
      'customerId': stop.customerId,
      'order': stop.order,
      'customerName': stop.customerName,
      'area': stop.area,
      'status': stop.status.name,
    };
  }

  RouteStopModel _stopFromJson(Map<String, dynamic> json) {
    final customer = _customerById(json['customerId'] as String);

    return RouteStopModel(
      customerId: json['customerId'] as String,
      order: json['order'] as int,
      customerName: customer?.name ?? json['customerName'] as String,
      area: customer?.area ?? json['area'] as String,
      status: _statusFromName(json['status'] as String?),
    );
  }

  CustomerModel? _customerById(String id) {
    final customer = MockCustomersRepository.instance.getCustomerById(id);
    if (customer == null || customer.id.isEmpty) return null;
    return customer;
  }

  RouteVisitStatus _statusFromName(String? name) {
    return RouteVisitStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => RouteVisitStatus.pending,
    );
  }

  List<RouteStopModel> _renumber(List<RouteStopModel> stops) {
    return [
      for (int i = 0; i < stops.length; i++) stops[i].copyWith(order: i + 1),
    ];
  }

  bool _countsAsCompleted(RouteStopModel stop) {
    return stop.status == RouteVisitStatus.completed ||
        stop.status == RouteVisitStatus.sold;
  }
}
