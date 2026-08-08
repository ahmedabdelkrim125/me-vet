// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_colors.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';

// import '../../home/domain/models/customer_alert_model.dart';
// import '../../home/presentation/widgets/customer_alert_section.dart';

// class CustomersScreen extends StatelessWidget {
//   const CustomersScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const followUpCustomers = [
//       CustomerAlertModel(
//         name: 'صيدلية النور',
//         subtitle: 'زيارة واحدة هذا الشهر',
//       ),
//       CustomerAlertModel(
//         name: 'عيادة الشفاء البيطرية',
//         subtitle: 'زيارتان هذا الشهر',
//       ),
//       CustomerAlertModel(
//         name: 'صيدلية الأمل',
//         subtitle: 'زيارة واحدة هذا الشهر',
//       ),
//       CustomerAlertModel(
//         name: 'عيادة الرحمة',
//         subtitle: 'لم تتم زيارته هذا الشهر',
//       ),
//     ];

//     const stalledCustomers = [
//       CustomerAlertModel(
//         name: 'مزرعة الدلتا',
//         subtitle: 'بدون طلبات منذ شهرين',
//       ),
//       CustomerAlertModel(
//         name: 'صيدلية الفا',
//         subtitle: 'بدون طلبات منذ شهرين',
//       ),
//       CustomerAlertModel(
//         name: 'مزرعة الوادي',
//         subtitle: 'بدون طلبات منذ 3 أشهر',
//       ),
//     ];

//     return Scaffold(
//       backgroundColor: AppColors.backgroundLight,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               padding: EdgeInsets.all(16.w),
//               color: Colors.white,
//               child: Row(
//                 children: [
//                   Icon(Icons.people_alt_outlined,
//                       color: AppColors.primary, size: 24.sp),
//                   SizedBox(width: 12.w),
//                   Text(
//                     'العملاء وخط السير',
//                     style: AppTextStyles.cairoBold18.copyWith(
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     onPressed: () {},
//                     icon: Icon(Icons.search_rounded,
//                         color: AppColors.primary, size: 24.sp),
//                   ),
//                   IconButton(
//                     onPressed: () {},
//                     icon: Icon(Icons.person_add_alt_1_rounded,
//                         color: AppColors.primaryGreen, size: 24.sp),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(16.w),
//                 child: context.isTablet
//                     ? Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Expanded(
//                             child: CustomerAlertSection(
//                               title: 'عملاء يحتاجون متابعة',
//                               icon: Icons.priority_high_rounded,
//                               accentColor: AppColors.statOrange,
//                               customers: followUpCustomers,
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           const Expanded(
//                             child: CustomerAlertSection(
//                               title: 'عملاء متوقفين',
//                               icon: Icons.pause_circle_outline_rounded,
//                               accentColor: AppColors.statBlue,
//                               customers: stalledCustomers,
//                             ),
//                           ),
//                         ],
//                       )
//                     : Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           const CustomerAlertSection(
//                             title: 'عملاء يحتاجون متابعة',
//                             icon: Icons.priority_high_rounded,
//                             accentColor: AppColors.statOrange,
//                             customers: followUpCustomers,
//                           ),
//                           SizedBox(height: 16.h),
//                           const CustomerAlertSection(
//                             title: 'عملاء متوقفين',
//                             icon: Icons.pause_circle_outline_rounded,
//                             accentColor: AppColors.statBlue,
//                             customers: stalledCustomers,
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import 'widgets/customers_list_view/customers_list_view.dart';
import 'widgets/route_view/route_view.dart';
import 'widgets/shared/customers_sub_view_switcher.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  int _subViewIndex = 0;
  bool _movingForward = true;

  void _onSubViewChanged(int index) {
    if (index == _subViewIndex) return;
    setState(() {
      _movingForward = index > _subViewIndex;
      _subViewIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: CustomersSubViewSwitcher(
                selectedIndex: _subViewIndex,
                onChanged: _onSubViewChanged,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offsetX = _movingForward ? 0.08 : -0.08;
                  final slide = Tween<Offset>(
                    begin: Offset(offsetX, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _subViewIndex == 0
                    ? const RouteView(key: ValueKey('route'))
                    : const CustomersListView(key: ValueKey('list')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
