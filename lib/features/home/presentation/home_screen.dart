import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../domain/models/customer_alert_model.dart';
import 'widgets/customer_alert_section.dart';
import 'widgets/daily_summary_section.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/route_progress_card.dart';
import 'widgets/visits_kpi_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const followUpCustomers = [
      CustomerAlertModel(
        name: 'صيدلية النور',
        subtitle: 'زيارة واحدة هذا الشهر',
      ),
      CustomerAlertModel(
        name: 'عيادة الشفاء البيطرية',
        subtitle: 'زيارتان هذا الشهر',
      ),
      CustomerAlertModel(
        name: 'صيدلية الأمل',
        subtitle: 'زيارة واحدة هذا الشهر',
      ),
    ];

    const stalledCustomers = [
      CustomerAlertModel(
        name: 'مزرعة الدلتا',
        subtitle: 'بدون طلبات منذ شهرين',
      ),
      CustomerAlertModel(
        name: 'صيدلية الفا',
        subtitle: 'بدون طلبات منذ شهرين',
      ),
    ];

    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              SizedBox(height: 20.h),
              const RouteProgressCard(
                routeName: 'خط اليوم — المنصورة 1',
                dayLabel: 'الأحد — ابدأ جولتك الآن',
                totalVisits: 12,
                completedVisits: 5,
              ),
              SizedBox(height: 16.h),
              const DailySummarySection(),
              SizedBox(height: 16.h),
              if (context.isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const VisitsKpiCard(
                            currentVisits: 9,
                            targetVisits: 12,
                          ),
                          SizedBox(height: 16.h),
                          const QuickActionsRow(),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CustomerAlertSection(
                            title: 'عملاء يحتاجون متابعة',
                            icon: Icons.priority_high_rounded,
                            accentColor: AppColors.statOrange,
                            customers: followUpCustomers,
                          ),
                          SizedBox(height: 16.h),
                          const CustomerAlertSection(
                            title: 'عملاء متوقفين',
                            icon: Icons.pause_circle_outline_rounded,
                            accentColor: AppColors.statBlue,
                            customers: stalledCustomers,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VisitsKpiCard(currentVisits: 9, targetVisits: 12),
                    SizedBox(height: 16.h),
                    const QuickActionsRow(),
                    SizedBox(height: 16.h),
                    const CustomerAlertSection(
                      title: 'عملاء يحتاجون متابعة',
                      icon: Icons.priority_high_rounded,
                      accentColor: AppColors.statOrange,
                      customers: followUpCustomers,
                    ),
                    SizedBox(height: 16.h),
                    const CustomerAlertSection(
                      title: 'عملاء متوقفين',
                      icon: Icons.pause_circle_outline_rounded,
                      accentColor: AppColors.statBlue,
                      customers: stalledCustomers,
                    ),
                  ],
                ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
