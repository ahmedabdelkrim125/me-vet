import '../domain/models/report_chart_point_model.dart';
import 'models/report_period_type.dart';

class MockDailyReportRepository {
  MockDailyReportRepository._();

  static final MockDailyReportRepository instance =
      MockDailyReportRepository._();

  Future<dynamic> getTimeline() async {
    return _MockTimeline();
  }

  Future<dynamic> buildReport({
    required ReportPeriodType period,
  }) async {
    return const _MockReport();
  }

  Future<List<ReportChartPointModel>> buildChartHistory({
    required int days,
  }) async {
    return <ReportChartPointModel>[];
  }
}

class _MockTimeline {
  bool get isWeeklyReportUnlocked => true;
  bool get isMonthlyReportUnlocked => true;
}

class _MockReport {
  const _MockReport();
}
