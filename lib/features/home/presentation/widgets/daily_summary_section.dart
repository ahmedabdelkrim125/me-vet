import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../domain/models/daily_stat_model.dart';
import '../../domain/models/weekly_financial_summary.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'stat_card.dart';

class DailySummarySection extends StatelessWidget {
  const DailySummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isLoading = state is HomeLoading || state is HomeInitial;
        final stats =
            state is HomeLoaded ? _statsFor(state.summary) : _placeholderStats;

        return Skeletonizer(
          enabled: isLoading,
          child: Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(child: StatCard(stat: stats[i])),
                if (i != stats.length - 1) SizedBox(width: 12.w),
              ],
            ],
          ),
        );
      },
    );
  }

  List<DailyStatModel> _statsFor(WeeklyFinancialSummary summary) {
    return [
      const DailyStatModel(
        label: 'إجمالي المبيعات',
        value: 'لسه مفيش بيانات',
        icon: HugeIcons.strokeRoundedChartUp,
        color: AppColors.primaryGreen,
        trendPercent: 0,
        showTrend: false,
      ),
      const DailyStatModel(
        label: 'إجمالي المرتجعات',
        value: 'لسه مفيش بيانات',
        icon: HugeIcons.strokeRoundedUndo,
        color: AppColors.statOrange,
        trendPercent: 0,
        showTrend: false,
      ),
      DailyStatModel(
        label: 'إجمالي التحصيل',
        value: '${summary.currentWeekCollections.toStringAsFixed(0)} ج.م',
        icon: HugeIcons.strokeRoundedWallet01,
        color: AppColors.statBlue,
        trendPercent: summary.collectionsTrendPercent,
      ),
    ];
  }

  static const _placeholderStats = [
    DailyStatModel(
      label: 'إجمالي المبيعات',
      value: '---',
      icon: HugeIcons.strokeRoundedChartUp,
      color: AppColors.primaryGreen,
      trendPercent: 0,
      showTrend: false,
    ),
    DailyStatModel(
      label: 'إجمالي المرتجعات',
      value: '---',
      icon: HugeIcons.strokeRoundedUndo,
      color: AppColors.statOrange,
      trendPercent: 0,
      showTrend: false,
    ),
    DailyStatModel(
      label: 'إجمالي التحصيل',
      value: '---',
      icon: HugeIcons.strokeRoundedWallet01,
      color: AppColors.statBlue,
      trendPercent: 0,
      showTrend: false,
    ),
  ];
}
