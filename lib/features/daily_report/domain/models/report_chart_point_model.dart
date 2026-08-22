/// One data point for the daily/weekly/monthly performance charts.
class ReportChartPointModel {
  final DateTime date;
  final double collections;
  final double invoicesValue;
  final int visitsCompleted;

  const ReportChartPointModel({
    required this.date,
    required this.collections,
    required this.invoicesValue,
    required this.visitsCompleted,
  });
}