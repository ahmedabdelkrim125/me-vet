// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../core/di/service_locator.dart';
// import '../../customer-visits/customers/domain/today_route_controller.dart';
// import '../../customer-visits/customers/screens/widgets/route_view/select_route_customers_sheet.dart';
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

//   Future<void> _selectTodayCustomers() async {
//     await _routeController.initialize();
//     if (!mounted) return;

//     final selected = await showSelectRouteCustomersSheet(
//       context,
//       initiallySelectedIds: _routeController.selectedCustomerIds,
//     );
//     if (selected == null) return;

//     await _routeController.setSelectedCustomers(selected);
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('تم تحديث خط اليوم (${selected.length} عميل)')),
//     );
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
//                             buttonText: 'تحديد عملاء اليوم',
//                             onButtonTap: _selectTodayCustomers,
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../core/di/service_locator.dart';
import 'cubit/home_cubit.dart';
import 'widgets/daily_summary_section.dart';
import 'widgets/home_header.dart';
import 'widgets/route_progress_card.dart';
import 'widgets/visits_kpi_card.dart';

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
                      const DailySummarySection(),
                      SizedBox(height: 14.h),
                      ValueListenableBuilder(
                        valueListenable: _routeController.stopsNotifier,
                        builder: (context, stops, _) {
                          return VisitsKpiCard(
                            currentVisits: _routeController.completedVisits,
                            targetVisits: _routeController.totalVisits,
                          );
                        },
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
