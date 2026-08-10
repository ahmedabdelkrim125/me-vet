import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'widgets/daily_summary_section.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_invoice_dialog.dart';
import 'widgets/route_progress_card.dart';
import 'widgets/visits_kpi_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const RouteProgressCard(
                routeName: 'خطة زياراتك اليوم',
                dayLabel: 'حدد عملاءك لتبدأ الجولة',
                totalVisits: 0,
                completedVisits: 0,
                buttonText: 'تحديد عملاء اليوم',
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
