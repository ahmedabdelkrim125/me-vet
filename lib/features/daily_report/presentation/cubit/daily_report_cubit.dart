import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/daily_report_repository.dart';
import '../../domain/models/report_period_type.dart';
import 'daily_report_state.dart';

class DailyReportCubit extends Cubit<DailyReportState> {
  final DailyReportRepository _repository;
  final String? _ownerSelectedRepId;
  ReportPeriodType _currentPeriod = ReportPeriodType.daily;

  DailyReportCubit(this._repository, {String? ownerSelectedRepId})
      : _ownerSelectedRepId = ownerSelectedRepId,
        super(const DailyReportInitial());

  Future<void> load() async {
    emit(const DailyReportLoading());
    await _fetchReport(_currentPeriod);
  }

  Future<void> refresh() async {
    await _fetchReport(_currentPeriod);
  }

  Future<void> selectPeriod(ReportPeriodType period) async {
    _currentPeriod = period;
    emit(const DailyReportLoading());
    await _fetchReport(period);
  }

  Future<void> _fetchReport(ReportPeriodType period) async {
    try {
      final now = DateTime.now();
      DateTime from;
      DateTime to;

      switch (period) {
        case ReportPeriodType.daily:
          from = DateTime(now.year, now.month, now.day);
          to = from.add(const Duration(days: 1));
          break;
        case ReportPeriodType.weekly:
          final daysSinceSaturday = (now.weekday + 1) % 7;
          from = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysSinceSaturday));
          to = from.add(const Duration(days: 7));
          break;
        case ReportPeriodType.monthly:
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 1);
          break;
      }

      final report = await _repository.getDailyReport(
        from: from,
        to: to,
        repId: _ownerSelectedRepId,
      );

      emit(DailyReportLoaded(report: report, selectedPeriod: period));
    } catch (e) {
      emit(DailyReportError(e.toString()));
    }
  }
}
