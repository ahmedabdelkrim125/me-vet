/// Which rollup window a report/section represents.
///
/// Daily is always available from day 1. Weekly only "unlocks" once the
/// rep has 7+ days of work history; monthly only once 30+ days exist —
/// see [RepWorkTimelineModel].
enum ReportPeriodType { daily, weekly, monthly }

extension ReportPeriodTypeX on ReportPeriodType {
  String get label {
    switch (this) {
      case ReportPeriodType.daily:
        return 'التقرير اليومي';
      case ReportPeriodType.weekly:
        return 'التقرير الأسبوعي';
      case ReportPeriodType.monthly:
        return 'التقرير الشهري';
    }
  }
}
