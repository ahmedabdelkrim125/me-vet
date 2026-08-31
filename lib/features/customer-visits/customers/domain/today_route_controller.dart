import 'package:flutter/foundation.dart';

import '../data/customers_repository.dart';
import '../data/visits_repository.dart';
import 'models/customer_model.dart';
import 'models/route_stop_model.dart';
import 'models/visit_status.dart';
import 'models/visit_history_model.dart';

class TodayRouteController {
  TodayRouteController._internal();

  static final TodayRouteController instance = TodayRouteController._internal();

  final ValueNotifier<List<RouteStopModel>> stopsNotifier =
      ValueNotifier<List<RouteStopModel>>(<RouteStopModel>[]);
  final ValueNotifier<List<VisitHistoryModel>> visitHistoryNotifier =
      ValueNotifier<List<VisitHistoryModel>>(<VisitHistoryModel>[]);

  bool _initialized = false;

  List<RouteStopModel> get stops => stopsNotifier.value;

  List<String> get selectedCustomerIds =>
      stops.map((stop) => stop.customerId).toList();

  int get totalVisits => stops.length;

  int get completedVisits => stops.where(_countsAsCompleted).length;

  int get remainingVisits => totalVisits - completedVisits;

  bool get shouldAskForNewDayDecision => false;

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
    await _reloadToday();
    _initialized = true;
  }

  Future<void> refresh() => _reloadToday();

  Future<void> _reloadToday() async {
    final rows = await VisitsRepository.instance.getVisitsForDay(DateTime.now());
    final loaded = <RouteStopModel>[];
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final customer = _customerById(row.customerId);
      if (customer == null) continue;
      loaded.add(RouteStopModel(
        visitId: row.id,
        customerId: row.customerId,
        order: i + 1,
        customerName: customer.name,
        area: customer.area,
        status: row.status,
        scheduledAt: row.scheduledAt,
        statusUpdatedAt: row.statusUpdatedAt,
      ));
    }
    stopsNotifier.value = loaded;
  }

  Future<void> setSelectedCustomers(List<CustomerModel> customers) async {
    await initialize();
    await VisitsRepository.instance
        .setTodayRoute(customers.map((c) => c.id).toList());
    await _reloadToday();
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await initialize();
    if (selectedCustomerIds.contains(customer.id)) return;
    final ids = [...selectedCustomerIds, customer.id];
    await VisitsRepository.instance.setTodayRoute(ids);
    await _reloadToday();
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    await initialize();
    final ids = List<String>.from(selectedCustomerIds);
    if (newIndex > oldIndex) newIndex -= 1;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    await VisitsRepository.instance.reorderToday(ids);
    await _reloadToday();
  }

  Future<void> updateStatus(
    String customerId,
    RouteVisitStatus status,
  ) async {
    await initialize();
    await VisitsRepository.instance.updateStatusByCustomer(customerId, status);
    await _reloadToday();
    await _reloadHistoryForCustomer(customerId);
  }

  Future<void> removeStop(String customerId) async {
    await initialize();
    await VisitsRepository.instance.removeFromToday(customerId);
    await _reloadToday();
  }

  Future<void> carryIncompleteToNewDay() async {
    await initialize();
    final ids = incompleteStops.map((s) => s.customerId).toList();
    await VisitsRepository.instance.setTodayRoute(ids);
    await _reloadToday();
  }

  Future<void> clearTodayRoute() async {
    await initialize();
    await VisitsRepository.instance.setTodayRoute(const []);
    await _reloadToday();
  }

  Future<void> loadHistoryForCustomer(String customerId) =>
      _reloadHistoryForCustomer(customerId);

  Future<void> _reloadHistoryForCustomer(String customerId) async {
    final rows =
        await VisitsRepository.instance.getVisitsForCustomer(customerId);
    final customer = _customerById(customerId);
    final history = List<VisitHistoryModel>.from(visitHistoryNotifier.value)
      ..removeWhere((v) => v.customerId == customerId);

    for (final row in rows) {
      history.add(VisitHistoryModel(
        visitId: row.id,
        customerId: row.customerId,
        customerName: customer?.name ?? '',
        area: customer?.area ?? '',
        status: row.status,
        scheduledAt: row.scheduledAt,
        statusUpdatedAt: row.statusUpdatedAt,
      ));
    }

    history.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    visitHistoryNotifier.value = List<VisitHistoryModel>.from(history);
  }

  CustomerModel? _customerById(String id) {
    final customer = CustomersRepository.instance.getCustomerById(id);
    if (customer == null || customer.id.isEmpty) return null;
    return customer;
  }

  bool _countsAsCompleted(RouteStopModel stop) {
    return stop.status == RouteVisitStatus.completed ||
        stop.status == RouteVisitStatus.sold;
  }
}
