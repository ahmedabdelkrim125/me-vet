// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../core/di/service_locator.dart';
// import '../../customer-visits/customers/presentation/controllers/today_route_controller.dart';
// import 'cubit/home_cubit.dart';
// import 'widgets/daily_summary_section.dart';
// import 'widgets/home_header.dart';
// import 'widgets/route_progress_card.dart';
// import 'widgets/visits_kpi_card.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TodayRouteController _routeController = TodayRouteController.instance;
//   late final HomeCubit _homeCubit;

//   @override
//   void initState() {
//     super.initState();
//     _routeController.initialize();
//     _homeCubit = sl<HomeCubit>()..loadWeeklySummary();
//   }

//   @override
//   void dispose() {
//     _homeCubit.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final horizontalPadding = context.isTablet ? 22.w : 16.w;
//     final maxContentWidth = context.isTablet ? 720.w : null;

//     return BlocProvider.value(
//       value: _homeCubit,
//       child: Scaffold(
//         backgroundColor: colors.background,
//         body: SafeArea(
//           child: RefreshIndicator(
//             onRefresh: () => _homeCubit.loadWeeklySummary(forceRefresh: true),
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     colors.primary.withOpacity(0.08),
//                     colors.background,
//                     colors.background,
//                   ],
//                   stops: const [0, 0.34, 1],
//                 ),
//               ),
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: EdgeInsets.fromLTRB(
//                   horizontalPadding,
//                   16.h,
//                   horizontalPadding,
//                   18.h,
//                 ),
//                 child: AdaptiveContentWrapper(
//                   maxWidth: maxContentWidth,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const HomeHeader(),
//                       SizedBox(height: 18.h),
//                       ValueListenableBuilder(
//                         valueListenable: _routeController.stopsNotifier,
//                         builder: (context, stops, _) {
//                           final totalVisits = _routeController.totalVisits;
//                           final completedVisits =
//                               _routeController.completedVisits;

//                           return RouteProgressCard(
//                             routeName: 'خطة زياراتك اليوم',
//                             dayLabel: totalVisits == 0
//                                 ? 'حدد عملاءك لتبدأ الجولة'
//                                 : 'خط اليوم فيه $totalVisits عميل',
//                             totalVisits: totalVisits,
//                             completedVisits: completedVisits,
//                           );
//                         },
//                       ),
//                       SizedBox(height: 14.h),
//                       const DailySummarySection(),
//                       SizedBox(height: 14.h),
//                       ValueListenableBuilder(
//                         valueListenable: _routeController.stopsNotifier,
//                         builder: (context, stops, _) {
//                           return VisitsKpiCard(
//                             currentVisits: _routeController.completedVisits,
//                             targetVisits: _routeController.totalVisits,
//                           );
//                         },
//                       ),
//                       SizedBox(height: 16.h),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../customer-visits/customers/presentation/controllers/today_route_controller.dart';
import 'cubit/home_cubit.dart';
import 'widgets/home_header.dart';
import 'widgets/route_progress_card.dart';
import 'widgets/add_expense_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodayRouteController _routeController = TodayRouteController.instance;
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _routeController.initialize();
    _homeCubit = sl<HomeCubit>()..loadWeeklySummary();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final horizontalPadding = context.isTablet ? 22.w : 16.w;
    final maxContentWidth = context.isTablet ? 720.w : null;

    return BlocProvider.value(
      value: _homeCubit,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _homeCubit.loadWeeklySummary(forceRefresh: true),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withOpacity(0.08),
                    colors.background,
                    colors.background,
                  ],
                  stops: const [0, 0.34, 1],
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16.h,
                  horizontalPadding,
                  18.h,
                ),
                child: AdaptiveContentWrapper(
                  maxWidth: maxContentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeHeader(),
                      SizedBox(height: 18.h),
                      ValueListenableBuilder(
                        valueListenable: _routeController.stopsNotifier,
                        builder: (context, stops, _) {
                          final totalVisits = _routeController.totalVisits;
                          final completedVisits =
                              _routeController.completedVisits;

                          return RouteProgressCard(
                            routeName: 'خطة زياراتك اليوم',
                            dayLabel: totalVisits == 0
                                ? 'حدد عملاءك لتبدأ الجولة'
                                : 'خط اليوم فيه $totalVisits عميل',
                            totalVisits: totalVisits,
                            completedVisits: completedVisits,
                          );
                        },
                      ),
                      SizedBox(height: 14.h),
                      Material(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        elevation: 1,
                        shadowColor: AppColors.primary.withOpacity(0.05),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () async {
                            final added = await showDialog<bool>(
                              context: context,
                              builder: (_) => const AddExpenseDialog(),
                            );
                            if (added == true) {
                              _homeCubit.loadWeeklySummary(forceRefresh: true);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(Icons.money_off_csred_outlined, color: AppColors.primaryGreen, size: 24.w),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    'إضافة مصروف',
                                    style: AppTextStyles.cairoBold18.copyWith(
                                      fontSize: 16.sp,
                                      color: colors.text,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: colors.textMuted, size: 16.w),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}