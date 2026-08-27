import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/customers_repository.dart';
import 'models/customer_model.dart';
import 'models/route_stop_model.dart';
import 'models/visit_status.dart';
import 'models/visit_history_model.dart';

class TodayRouteController {
  TodayRouteController._internal();

  static final TodayRouteController instance = TodayRouteController._internal();

  static const String _storageKey = 'today_route_stops';
  static const String _routeStartedAtKey = 'today_route_started_at';
  static const String _visitHistoryStorageKey = 'customer_visit_history';

  final ValueNotifier<List<RouteStopModel>> stopsNotifier =
      ValueNotifier<List<RouteStopModel>>(<RouteStopModel>[]);
  final ValueNotifier<List<VisitHistoryModel>> visitHistoryNotifier =
      ValueNotifier<List<VisitHistoryModel>>(<VisitHistoryModel>[]);

  bool _initialized = false;
  DateTime? _routeStartedAt;

  List<RouteStopModel> get stops => stopsNotifier.value;

  List<String> get selectedCustomerIds =>
      stops.map((stop) => stop.customerId).toList();

  int get totalVisits => stops.length;

  int get completedVisits => stops.where(_countsAsCompleted).length;

  int get remainingVisits => totalVisits - completedVisits;

  bool get shouldAskForNewDayDecision {
    final startedAt = _routeStartedAt;
    if (startedAt == null || stops.isEmpty) return false;
    return DateTime.now().difference(startedAt).inHours >= 24;
  }

  List<RouteStopModel> get incompleteStops =>
      stops.where((stop) => !_countsAsCompleted(stop)).toList();

  List<VisitHistoryModel> visitsForCustomer(String customerId) {
    final visits = visitHistoryNotifier.value
        .where((visit) => visit.customerId == customerId)
        .toList();
    visits.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return visits;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await CustomersRepository.instance.initialize();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _routeStartedAt = _dateTimeFromString(prefs.getString(_routeStartedAtKey));
    visitHistoryNotifier.value = _loadVisitHistory(prefs);

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
    await _upsertHistoryForStops(stopsNotifier.value);
    _initialized = true;
  }

  Future<void> setSelectedCustomers(List<CustomerModel> customers) async {
    await initialize();

    final previousStatuses = {
      for (final stop in stops) stop.customerId: stop.status,
    };
    final selectedIds = customers.map((customer) => customer.id).toSet();
    final removedPendingVisitIds = stops
        .where((stop) =>
            !selectedIds.contains(stop.customerId) &&
            stop.status == RouteVisitStatus.pending)
        .map((stop) => stop.visitId)
        .toList();

    final now = DateTime.now();
    if (customers.isNotEmpty) _routeStartedAt ??= now;

    final nextStops = [
      for (int i = 0; i < customers.length; i++)
        RouteStopModel(
          visitId: _previousVisitIdFor(customers[i].id) ??
              _buildVisitId(customers[i].id, now),
          customerId: customers[i].id,
          order: i + 1,
          customerName: customers[i].name,
          area: customers[i].area,
          status: previousStatuses[customers[i].id] ?? RouteVisitStatus.pending,
          scheduledAt: _previousScheduledAtFor(customers[i].id) ?? now,
          statusUpdatedAt: _previousStatusUpdatedAtFor(customers[i].id) ?? now,
        ),
    ];

    await _setStops(nextStops);
    for (final visitId in removedPendingVisitIds) {
      await _removeHistory(visitId);
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await initialize();
    if (selectedCustomerIds.contains(customer.id)) return;

    final now = DateTime.now();
    _routeStartedAt ??= now;

    await _setStops([
      ...stops,
      RouteStopModel(
        visitId: _buildVisitId(customer.id, now),
        customerId: customer.id,
        order: stops.length + 1,
        customerName: customer.name,
        area: customer.area,
        status: RouteVisitStatus.pending,
        scheduledAt: now,
        statusUpdatedAt: now,
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
    final now = DateTime.now();
    final nextStops = [
      for (final stop in stops)
        stop.customerId == customerId
            ? stop.copyWith(status: status, statusUpdatedAt: now)
            : stop,
    ];
    await _setStops(nextStops);
  }

  Future<void> removeStop(String customerId) async {
    await initialize();
    final stop = _existingStopFor(customerId);
    await _setStops(
      _renumber(stops.where((stop) => stop.customerId != customerId).toList()),
    );
    if (stop != null && stop.status == RouteVisitStatus.pending) {
      await _removeHistory(stop.visitId);
    }
  }

  Future<void> carryIncompleteToNewDay() async {
    await initialize();

    final now = DateTime.now();
    final nextStops = [
      for (int i = 0; i < incompleteStops.length; i++)
        incompleteStops[i].copyWith(
          visitId: _buildVisitId(incompleteStops[i].customerId, now),
          order: i + 1,
          status: RouteVisitStatus.pending,
          scheduledAt: now,
          statusUpdatedAt: now,
        ),
    ];

    _routeStartedAt = now;
    await _setStops(nextStops);
  }

  Future<void> clearTodayRoute() async {
    await initialize();
    _routeStartedAt = null;
    await _setStops(<RouteStopModel>[]);
  }

  Future<void> _setStops(List<RouteStopModel> nextStops) async {
    if (nextStops.isEmpty) _routeStartedAt = null;
    stopsNotifier.value = List<RouteStopModel>.from(nextStops);
    await _upsertHistoryForStops(nextStops);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(stops.map(_stopToJson).toList());
    await prefs.setString(_storageKey, encoded);
    if (_routeStartedAt == null || stops.isEmpty) {
      await prefs.remove(_routeStartedAtKey);
    } else {
      await prefs.setString(
        _routeStartedAtKey,
        _routeStartedAt!.toIso8601String(),
      );
    }
  }

  Map<String, dynamic> _stopToJson(RouteStopModel stop) {
    return {
      'customerId': stop.customerId,
      'order': stop.order,
      'customerName': stop.customerName,
      'area': stop.area,
      'status': stop.status.name,
      'visitId': stop.visitId,
      'scheduledAt': stop.scheduledAt?.toIso8601String(),
      'statusUpdatedAt': stop.statusUpdatedAt?.toIso8601String(),
    };
  }

  RouteStopModel _stopFromJson(Map<String, dynamic> json) {
    final customer = _customerById(json['customerId'] as String);
    final now = DateTime.now();
    final scheduledAt =
        _dateTimeFromString(json['scheduledAt'] as String?) ?? now;

    return RouteStopModel(
      visitId: json['visitId'] as String? ??
          _buildVisitId(json['customerId'] as String, scheduledAt),
      customerId: json['customerId'] as String,
      order: json['order'] as int,
      customerName: customer?.name ?? json['customerName'] as String,
      area: customer?.area ?? json['area'] as String,
      status: _statusFromName(json['status'] as String?),
      scheduledAt: scheduledAt,
      statusUpdatedAt:
          _dateTimeFromString(json['statusUpdatedAt'] as String?) ??
              scheduledAt,
    );
  }

  CustomerModel? _customerById(String id) {
    final customer = CustomersRepository.instance.getCustomerById(id);
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

  String? _previousVisitIdFor(String customerId) {
    return _existingStopFor(customerId)?.visitId;
  }

  DateTime? _previousScheduledAtFor(String customerId) {
    return _existingStopFor(customerId)?.scheduledAt;
  }

  DateTime? _previousStatusUpdatedAtFor(String customerId) {
    return _existingStopFor(customerId)?.statusUpdatedAt;
  }

  RouteStopModel? _existingStopFor(String customerId) {
    for (final stop in stops) {
      if (stop.customerId == customerId) return stop;
    }
    return null;
  }

  String _buildVisitId(String customerId, DateTime dateTime) {
    return '$customerId-${dateTime.microsecondsSinceEpoch}';
  }

  DateTime? _dateTimeFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<VisitHistoryModel> _loadVisitHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_visitHistoryStorageKey);
    if (raw == null || raw.isEmpty) return <VisitHistoryModel>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => VisitHistoryModel.fromJson(
              entry as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> _upsertHistoryForStops(List<RouteStopModel> stops) async {
    if (stops.isEmpty) return;

    final history = List<VisitHistoryModel>.from(visitHistoryNotifier.value);
    for (final stop in stops) {
      final visitId = stop.visitId;
      final scheduledAt = stop.scheduledAt;
      if (visitId == null || scheduledAt == null) continue;

      final index = history.indexWhere((visit) => visit.visitId == visitId);
      final visit = VisitHistoryModel(
        visitId: visitId,
        customerId: stop.customerId,
        customerName: stop.customerName,
        area: stop.area,
        status: stop.status,
        scheduledAt: scheduledAt,
        statusUpdatedAt: stop.statusUpdatedAt ?? scheduledAt,
      );

      if (index == -1) {
        history.add(visit);
      } else {
        history[index] = visit;
      }
    }

    await _setVisitHistory(history);
  }

  Future<void> _removeHistory(String? visitId) async {
    if (visitId == null) return;
    final history = visitHistoryNotifier.value
        .where((visit) => visit.visitId != visitId)
        .toList();
    await _setVisitHistory(history);
  }

  Future<void> _setVisitHistory(List<VisitHistoryModel> history) async {
    history.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    visitHistoryNotifier.value = List<VisitHistoryModel>.from(history);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _visitHistoryStorageKey,
      jsonEncode(history.map((visit) => visit.toJson()).toList()),
    );
  }

  bool _countsAsCompleted(RouteStopModel stop) {
    return stop.status == RouteVisitStatus.completed ||
        stop.status == RouteVisitStatus.sold;
  }
}
