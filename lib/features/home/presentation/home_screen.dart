import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../customer-visits/customers/data/route_day_store.dart';
import '../../customer-visits/customers/domain/models/visit_status.dart';
import 'widgets/daily_summary_section.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_invoice_dialog.dart';
import 'widgets/route_progress_card.dart';
import 'widgets/visits_kpi_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToCustomers});
  final VoidCallback? onNavigateToCustomers;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _routeStore = RouteDayStore.instance;

  @override
  void initState() {
    _routeStore.initialize();
    super.initState();
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
                valueListenable: _routeStore.stopsNotifier,
                builder: (context, stops, _) {
                    final completed = stops
                        .where((s) =>
                            s.status == RouteVisitStatus.completed ||
                            s.status == RouteVisitStatus.sold)
                        .length;
                    return RouteProgressCard(
                    routeName: 'خطة زياراتك اليوم',
                    dayLabel: stops.isEmpty
                        ? 'حدد عملاءك لتبدأ الجولة'
                        : '$completed من ${stops.length} زيارة اليوم',
                    totalVisits: stops.length,
                    completedVisits: completed,
                    buttonText: 'تحديد عملاء اليوم',
                    onStartTap: widget.onNavigateToCustomers,
                  );
                }
              ),
              SizedBox(height: 16.h),
              const DailySummarySection(),
              SizedBox(height: 16.h),
              const VisitsKpiCard(
                currentVisits: 9,
                targetVisits: 12,
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }
}
