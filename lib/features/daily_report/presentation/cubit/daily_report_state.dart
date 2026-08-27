import '../../domain/models/report_chart_point_model.dart';
import '../../domain/models/report_period_type.dart';
import '../../domain/models/rep_work_timeline_model.dart';
import '../../domain/models/representative_report_model.dart';

abstract class DailyReportState {
  const DailyReportState();
}

class DailyReportInitial extends DailyReportState {
  const DailyReportInitial();
}

class DailyReportLoading extends DailyReportState {
  const DailyReportLoading();
}

class DailyReportLoaded extends DailyReportState {
  final RepWorkTimelineModel timeline;
  final RepresentativeReportModel dailyReport;
  final RepresentativeReportModel? weeklyReport;
  final RepresentativeReportModel? monthlyReport;
  final ReportPeriodType selectedPeriod;
  final List<ReportChartPointModel> chartHistory;

  const DailyReportLoaded({
    required this.timeline,
    required this.dailyReport,
    required this.weeklyReport,
    required this.monthlyReport,
    required this.selectedPeriod,
    required this.chartHistory,
  });

  /// The report matching [selectedPeriod], falling back to daily if the
  /// selected period isn't unlocked/loaded yet.
  RepresentativeReportModel get selectedReport {
    switch (selectedPeriod) {
      case ReportPeriodType.daily:
        return dailyReport;
      case ReportPeriodType.weekly:
        return weeklyReport ?? dailyReport;
      case ReportPeriodType.monthly:
        return monthlyReport ?? dailyReport;
    }
  }

  DailyReportLoaded copyWith({
    RepWorkTimelineModel? timeline,
    RepresentativeReportModel? dailyReport,
    RepresentativeReportModel? weeklyReport,
    RepresentativeReportModel? monthlyReport,
    ReportPeriodType? selectedPeriod,
    List<ReportChartPointModel>? chartHistory,
  }) {
    return DailyReportLoaded(
      timeline: timeline ?? this.timeline,
      dailyReport: dailyReport ?? this.dailyReport,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      monthlyReport: monthlyReport ?? this.monthlyReport,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      chartHistory: chartHistory ?? this.chartHistory,
    );
  }
}

class DailyReportError extends DailyReportState {
  final String message;
  const DailyReportError(this.message);
}