import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/mock_daily_report_repository.dart';
import '../../domain/models/report_period_type.dart';
import 'daily_report_state.dart';

class DailyReportCubit extends Cubit<DailyReportState> {
  DailyReportCubit({MockDailyReportRepository? repository})
      : _repository = repository ?? MockDailyReportRepository.instance,
        super(const DailyReportInitial());

  final MockDailyReportRepository _repository;

  Future<void> load() async {
    emit(const DailyReportLoading());
    try {
      final timeline = await _repository.getTimeline();

      final daily = await _repository.buildReport(period: ReportPeriodType.daily);
      final weekly = timeline.isWeeklyReportUnlocked
          ? await _repository.buildReport(period: ReportPeriodType.weekly)
          : null;
      final monthly = timeline.isMonthlyReportUnlocked
          ? await _repository.buildReport(period: ReportPeriodType.monthly)
          : null;

      final chartHistory = await _repository.buildChartHistory(days: 30);

      emit(DailyReportLoaded(
        timeline: timeline,
        dailyReport: daily,
        weeklyReport: weekly,
        monthlyReport: monthly,
        selectedPeriod: ReportPeriodType.daily,
        chartHistory: chartHistory,
      ));
    } catch (e) {
      emit(DailyReportError('تعذر تحميل التقرير: $e'));
    }
  }

  Future<void> refresh() => load();

  void selectPeriod(ReportPeriodType period) {
    final current = state;
    if (current is! DailyReportLoaded) return;

    final isUnlocked = switch (period) {
      ReportPeriodType.daily => true,
      ReportPeriodType.weekly => current.timeline.isWeeklyReportUnlocked,
      ReportPeriodType.monthly => current.timeline.isMonthlyReportUnlocked,
    };
    if (!isUnlocked) return;

    emit(current.copyWith(selectedPeriod: period));
  }
}