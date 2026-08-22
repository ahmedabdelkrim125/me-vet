import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/report_chart_point_model.dart';

class ReportChartsSection extends StatelessWidget {
  final List<ReportChartPointModel> points;
  const ReportChartsSection({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أداء آخر 30 يوم',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 14.sp)),
        SizedBox(height: 10.h),
        Row(
          children: [
            _Dot(color: colors.primary),
            SizedBox(width: 6.w),
            Text('تحصيل',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 10.sp)),
            SizedBox(width: 16.w),
            _Dot(color: colors.statBlue),
            SizedBox(width: 6.w),
            Text('فواتير',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 10.sp)),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          height: 220.h,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colors.border),
          ),
          child: LineChart(_lineData(colors)),
        ),
        SizedBox(height: 14.h),
        Text('زيارات مكتملة يوميًا',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 13.sp)),
        SizedBox(height: 10.h),
        Container(
          height: 180.h,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colors.border),
          ),
          child: BarChart(_barData(colors)),
        ),
      ],
    );
  }

  LineChartData _lineData(AppColorScheme colors) {
    final collectionsSpots = <FlSpot>[];
    final invoicesSpots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      collectionsSpots.add(FlSpot(i.toDouble(), points[i].collections));
      invoicesSpots.add(FlSpot(i.toDouble(), points[i].invoicesValue));
    }
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: collectionsSpots,
          isCurved: true,
          color: colors.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: invoicesSpots,
          isCurved: true,
          color: colors.statBlue,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  BarChartData _barData(AppColorScheme colors) {
    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int i = 0; i < points.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: points[i].visitsCompleted.toDouble(),
              color: colors.primary,
              width: 4,
            ),
          ]),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}