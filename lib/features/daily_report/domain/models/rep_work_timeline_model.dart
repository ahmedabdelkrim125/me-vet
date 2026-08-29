import 'report_period_type.dart';

/// Tracks "day 1 of work" for the active rep and derives which report
/// sections should be visible. This is the source of truth for the
/// Day 1 / Day 7 / Day 30 automation described in the requirements.
class RepWorkTimelineModel {
  final DateTime firstWorkDate;
  final DateTime asOf;

  const RepWorkTimelineModel({
    required this.firstWorkDate,
    required this.asOf,
  });

  /// 1-indexed: the day the rep started counts as day 1.
  int get workDayNumber {
    final start =
        DateTime(firstWorkDate.year, firstWorkDate.month, firstWorkDate.day);
    final now = DateTime(asOf.year, asOf.month, asOf.day);
    return now.difference(start).inDays + 1;
  }

  bool get isWeeklyReportUnlocked => workDayNumber >= 7;
  bool get isMonthlyReportUnlocked => workDayNumber >= 30;

  List<ReportPeriodType> get availablePeriods => [
        ReportPeriodType.daily,
        if (isWeeklyReportUnlocked) ReportPeriodType.weekly,
        if (isMonthlyReportUnlocked) ReportPeriodType.monthly,
      ];
}
