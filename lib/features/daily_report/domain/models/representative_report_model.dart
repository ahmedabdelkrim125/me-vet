import 'cash_settlement_model.dart';
import 'client_visit_stats_model.dart';
import 'inventory_movement_summary_model.dart';
import 'report_period_type.dart';

/// The full read-only report shown for a given period (day / week / month).
/// This is what the UI binds to directly — one object, fully computed.
class RepresentativeReportModel {
  final String repId;
  final String repName;
  final String vehiclePlateNumber;
  final String vehicleDriverName;

  final ReportPeriodType periodType;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Day number since the rep's first work day (1-indexed). Only
  /// meaningful for [ReportPeriodType.daily].
  final int workDayNumber;

  final ClientVisitStatsModel clientStats;
  final CashSettlementModel cashSettlement;
  final InventoryMovementSummaryModel inventorySummary;

  const RepresentativeReportModel({
    required this.repId,
    required this.repName,
    required this.vehiclePlateNumber,
    required this.vehicleDriverName,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.workDayNumber,
    required this.clientStats,
    required this.cashSettlement,
    required this.inventorySummary,
  });

  bool get isSameDayAs =>
      periodType == ReportPeriodType.daily &&
      periodStart.year == periodEnd.year &&
      periodStart.month == periodEnd.month &&
      periodStart.day == periodEnd.day;
}
