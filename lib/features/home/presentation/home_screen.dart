import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../customer-visits/customers/domain/today_route_controller.dart';
import '../../customer-visits/customers/screens/widgets/route_view/select_route_customers_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _routeController.initialize();
  }

  Future<void> _selectTodayCustomers() async {
    await _routeController.initialize();
    if (!mounted) return;

    final selected = await showSelectRouteCustomersSheet(
      context,
      initiallySelectedIds: _routeController.selectedCustomerIds,
    );
    if (selected == null) return;

    await _routeController.setSelectedCustomers(selected);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث خط اليوم (${selected.length} عميل)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.backgroundLight,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     debugPrint('تم الضغط على فاتورة سريعة');
      //
      //     showDialog(
      //       context: context,
      //       builder: (context) => const QuickInvoiceDialog(),
      //     );
      //   },
      //   backgroundColor: AppColors.primaryGreen,
      //   icon: HugeIcon(
      //     icon: HugeIcons.strokeRoundedInvoice01,
      //     color: Colors.white,
      //     size: 20.sp,
      //   ),
      //   label: Text(
      //     'فاتورة سريعة',
      //     style: AppTextStyles.cairoMedium16.copyWith(
      //       color: Colors.white,
      //       fontSize: 14.sp,
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              SizedBox(height: 20.h),
              ValueListenableBuilder(
                valueListenable: _routeController.stopsNotifier,
                builder: (context, stops, _) {
                  final totalVisits = _routeController.totalVisits;
                  final completedVisits = _routeController.completedVisits;

                  return RouteProgressCard(
                    routeName: 'خطة زياراتك اليوم',
                    dayLabel: totalVisits == 0
                        ? 'حدد عملاءك لتبدأ الجولة'
                        : 'خط اليوم فيه $totalVisits عميل',
                    totalVisits: totalVisits,
                    completedVisits: completedVisits,
                    buttonText: 'تحديد عملاء اليوم',
                    onButtonTap: _selectTodayCustomers,
                  );
                },
              ),
              SizedBox(height: 16.h),
              const DailySummarySection(),
              SizedBox(height: 16.h),
              ValueListenableBuilder(
                valueListenable: _routeController.stopsNotifier,
                builder: (context, stops, _) {
                  return VisitsKpiCard(
                    currentVisits: _routeController.completedVisits,
                    targetVisits: _routeController.totalVisits,
                  );
                },
              ),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
