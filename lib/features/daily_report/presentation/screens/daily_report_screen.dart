import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/daily_report/domain/models/report_period_type.dart';
import 'package:mivet_app/features/daily_report/presentation/screens/widgets/cash_settlement_card.dart';
import 'package:mivet_app/features/daily_report/presentation/screens/widgets/client_stats_card.dart';
import 'package:mivet_app/features/daily_report/presentation/screens/widgets/inventory_summary_card.dart';
import 'package:mivet_app/features/daily_report/presentation/screens/widgets/report_charts_section.dart';
import 'package:mivet_app/features/daily_report/presentation/screens/widgets/report_period_tabs.dart';
import 'package:printing/printing.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/report_pdf_builder.dart';
import '../cubit/daily_report_cubit.dart';
import '../cubit/daily_report_state.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailyReportCubit()..load(),
      child: const _DailyReportBody(),
    );
  }
}

class _DailyReportBody extends StatelessWidget {
  const _DailyReportBody();

  String _fmt(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.background,
      child: SafeArea(
        child: BlocBuilder<DailyReportCubit, DailyReportState>(
          builder: (context, state) {
            if (state is DailyReportError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.textMuted)),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => context.read<DailyReportCubit>().load(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            if (state is! DailyReportLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final report = state.selectedReport;

            return RefreshIndicator(
              onRefresh: () => context.read<DailyReportCubit>().refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                children: [
                  Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.heroBackground, colors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.periodType.label,
                            style: AppTextStyles.cairoBold18
                                .copyWith(color: Colors.white, fontSize: 16.sp)),
                        SizedBox(height: 6.h),
                        Text('المندوب: ${report.repName}',
                            style: AppTextStyles.almaraiRegular14
                                .copyWith(color: Colors.white70, fontSize: 12.sp)),
                        Text(
                          'العربية: ${report.vehiclePlateNumber} — ${report.vehicleDriverName}',
                          style: AppTextStyles.almaraiRegular14
                              .copyWith(color: Colors.white70, fontSize: 12.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_fmt(report.periodStart)} → ${_fmt(report.periodEnd)}  ·  يوم عمل رقم ${report.workDayNumber}',
                          style: AppTextStyles.almaraiRegular14
                              .copyWith(color: Colors.white70, fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ReportPeriodTabs(
                    availablePeriods: state.timeline.availablePeriods,
                    selected: state.selectedPeriod,
                    onChanged: (p) => context.read<DailyReportCubit>().selectPeriod(p),
                  ),
                  SizedBox(height: 16.h),
                  ClientStatsCard(stats: report.clientStats),
                  SizedBox(height: 16.h),
                  CashSettlementCard(cash: report.cashSettlement),
                  SizedBox(height: 16.h),
                  InventorySummaryCard(inventory: report.inventorySummary),
                  SizedBox(height: 20.h),
                  ReportChartsSection(points: state.chartHistory),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () async {
                              final bytes = await ReportPdfBuilder.build(report);
                              await Printing.layoutPdf(onLayout: (_) async => bytes);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.print_outlined,
                                      color: Colors.white, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text('طباعة',
                                      style: AppTextStyles.cairoMedium16
                                          .copyWith(color: Colors.white, fontSize: 13.sp)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Material(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () async {
                              final bytes = await ReportPdfBuilder.build(report);
                              await Printing.sharePdf(
                                bytes: bytes,
                                filename: 'report_${report.periodType.name}.pdf',
                              );
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.ios_share_rounded,
                                      color: colors.primary, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text('تصدير PDF',
                                      style: AppTextStyles.cairoMedium16
                                          .copyWith(color: colors.primary, fontSize: 13.sp)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}