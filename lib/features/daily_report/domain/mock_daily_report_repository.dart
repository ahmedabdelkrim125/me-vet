import '../../customer-visits/customers/data/customers_repository.dart';
import '../../customer-visits/customers/data/invoices_repository.dart';
import '../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../customer-visits/customers/data/visits_repository.dart';
import '../../customer-visits/customers/domain/today_route_controller.dart';
import '../../customer-visits/customers/domain/models/visit_status.dart';
import '../../inventory/domain/mock_inventory_repository.dart';
import '../../inventory/domain/mock_stock_adjustments_repository.dart';
import '../../inventory/domain/models/stock_adjustment_model.dart';
import '../../inventory/domain/models/stock_movement_type.dart';
import '../../rep_session/data/rep_session_store.dart';
import 'models/cash_settlement_model.dart';
import 'models/client_visit_stats_model.dart';
import 'models/inventory_movement_summary_model.dart';
import 'models/report_chart_point_model.dart';
import 'models/report_period_type.dart';
import 'models/rep_work_timeline_model.dart';
import 'models/representative_report_model.dart';

class _PeriodBounds {
  final DateTime start;
  final DateTime end; // exclusive
  const _PeriodBounds(this.start, this.end);
}

class MockDailyReportRepository {
  MockDailyReportRepository._();
  static final MockDailyReportRepository instance =
      MockDailyReportRepository._();

  Future<void> _ensureSourcesReady() async {
    await CustomersRepository.instance.initialize();
    await MockInventoryRepository.instance.init();
    await TodayRouteController.instance.initialize();
    await MockStockAdjustmentsRepository.instance.initialize();
  }

  Future<RepWorkTimelineModel> getTimeline() async {
    final rep = await RepSessionStore.instance.getActiveRep();
    return RepWorkTimelineModel(
      firstWorkDate: rep?.createdAt ?? DateTime.now(),
      asOf: DateTime.now(),
    );
  }

  _PeriodBounds _boundsFor(ReportPeriodType period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriodType.daily:
        return _PeriodBounds(today, today.add(const Duration(days: 1)));
      case ReportPeriodType.weekly:
        return _PeriodBounds(
          today.subtract(const Duration(days: 6)),
          today.add(const Duration(days: 1)),
        );
      case ReportPeriodType.monthly:
        return _PeriodBounds(
          today.subtract(const Duration(days: 29)),
          today.add(const Duration(days: 1)),
        );
    }
  }

  Future<RepresentativeReportModel> buildReport({
    required ReportPeriodType period,
  }) async {
    await _ensureSourcesReady();

    final rep = await RepSessionStore.instance.getActiveRep();
    final timeline = await getTimeline();
    final bounds = _boundsFor(period, DateTime.now());

    final vehicle = MockInventoryRepository.instance.currentVehicle;
    final products = MockInventoryRepository.instance.products.value;
    double priceOf(String productId) {
      for (final p in products) {
        if (p.id == productId) return p.basePrice;
      }
      return 0;
    }

    // --- Client visit stats (today's route) ---
    final stops = TodayRouteController.instance.stops;
    final clientStats = ClientVisitStatsModel(
      totalAssignedClients: stops.length,
      visitedClients:
          stops.where((s) => s.status != RouteVisitStatus.pending).length,
      completedOrSoldClients: stops
          .where((s) =>
              s.status == RouteVisitStatus.completed ||
              s.status == RouteVisitStatus.sold)
          .length,
      noOrderClients:
          stops.where((s) => s.status == RouteVisitStatus.noOrder).length,
      notReachedClients:
          stops.where((s) => s.status == RouteVisitStatus.notReached).length,
    );

    // --- Cash settlement ---
    final invoices = await InvoicesRepository.instance
        .getInvoicesInRange(bounds.start, bounds.end);
    final collections = await CustomersRepository.instance
        .getAllCollectionsInRange(bounds.start, bounds.end);

    final cashOnNewInvoices = collections
        .where((c) => c.source == CollectionSource.newInvoicePayment)
        .fold(0.0, (sum, c) => sum + c.amount);
    final cashOnOldDebt = collections
        .where((c) => c.source == CollectionSource.oldDebtPayment)
        .fold(0.0, (sum, c) => sum + c.amount);

    final outstanding = CustomersRepository.instance.customers
        .fold(0.0, (sum, c) => sum + c.currentBalance);

    final cashSettlement = CashSettlementModel(
      totalInvoicesValue: invoices.fold(0.0, (sum, inv) => sum + inv.amount),
      totalInvoicesCount: invoices.length,
      cashCollectedOnNewInvoices: cashOnNewInvoices,
      cashCollectedOnOldDebt: cashOnOldDebt,
      roadExpenses: 0, // TODO: no expense-entry UI yet
      outstandingCreditOutside: outstanding,
    );

    // --- Inventory movement summary ---
    final movements = MockInventoryRepository.instance.movements.value.where(
      (m) =>
          !m.createdAt.isBefore(bounds.start) &&
          m.createdAt.isBefore(bounds.end),
    );
    double loadedValue = 0;
    double addedValue = 0;
    for (final m in movements) {
      final value = m.quantity * priceOf(m.productId);
      if (m.type == StockMovementType.loadedToVehicle) {
        loadedValue += value;
      } else {
        addedValue += value;
      }
    }

    final remainingVehicleValue = MockInventoryRepository
        .instance.vehicleStock.value
        .fold(0.0, (sum, s) => sum + s.quantity * priceOf(s.productId));
    final remainingWarehouseValue = MockInventoryRepository
        .instance.mainWarehouseStock.value
        .fold(0.0, (sum, s) => sum + s.quantity * priceOf(s.productId));

    final returnsValue = MockStockAdjustmentsRepository.instance
        .totalValueInRange(
            bounds.start, bounds.end, StockAdjustmentType.returned);
    final damagedValue = MockStockAdjustmentsRepository.instance
        .totalValueInRange(
            bounds.start, bounds.end, StockAdjustmentType.damaged);

    final inventorySummary = InventoryMovementSummaryModel(
      loadedFromWarehouseValue: loadedValue,
      addedToWarehouseValue: addedValue,
      soldFromVehicleValue: cashSettlement.totalInvoicesValue,
      remainingVehicleStockValue: remainingVehicleValue,
      remainingWarehouseStockValue: remainingWarehouseValue,
      returnsValue: returnsValue,
      damagedGoodsValue: damagedValue,
    );

    return RepresentativeReportModel(
      repId: rep?.id ?? 'unknown',
      repName: rep?.name ?? vehicle.repName,
      vehiclePlateNumber: vehicle.plateNumber,
      vehicleDriverName: vehicle.driverName,
      periodType: period,
      periodStart: bounds.start,
      periodEnd: bounds.end.subtract(const Duration(days: 1)),
      workDayNumber: timeline.workDayNumber,
      clientStats: clientStats,
      cashSettlement: cashSettlement,
      inventorySummary: inventorySummary,
    );
  }

  /// Daily points for the last [days] days — feeds the fl_chart widgets.
  Future<List<ReportChartPointModel>> buildChartHistory({int days = 30}) async {
    await _ensureSourcesReady();
    final now = DateTime.now();
    final points = <ReportChartPointModel>[];

    for (int i = days - 1; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      final invoices = await InvoicesRepository.instance
          .getInvoicesInRange(day, nextDay);
      final collections = await CustomersRepository.instance
          .getAllCollectionsInRange(day, nextDay);
      final dayVisits =
          await VisitsRepository.instance.getVisitsInRange(day, nextDay);
      final visitsCompleted = dayVisits
          .where((v) =>
              v.status == RouteVisitStatus.completed ||
              v.status == RouteVisitStatus.sold)
          .length;

      points.add(ReportChartPointModel(
        date: day,
        collections: collections.fold(0.0, (sum, c) => sum + c.amount),
        invoicesValue: invoices.fold(0.0, (sum, inv) => sum + inv.amount),
        visitsCompleted: visitsCompleted,
      ));
    }

    return points;
  }
}
