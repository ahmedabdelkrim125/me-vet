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
