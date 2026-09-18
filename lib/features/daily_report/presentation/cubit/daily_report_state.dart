import '../../domain/models/report_period_type.dart';
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
  final RepresentativeReportModel report;
  final ReportPeriodType selectedPeriod;

  const DailyReportLoaded({
    required this.report,
    required this.selectedPeriod,
  });
}

class DailyReportError extends DailyReportState {
  final String message;
  const DailyReportError(this.message);
}
