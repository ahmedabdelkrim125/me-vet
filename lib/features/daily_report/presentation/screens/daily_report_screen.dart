// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:printing/printing.dart';
// import 'package:skeletonizer/skeletonizer.dart';
// import '../../../../core/const/app_images.dart';
// import '../../../../core/di/service_locator.dart';
// import '../../../../core/theme/app_color_scheme_extension.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/utils/responsive_extension.dart';
// import '../../domain/models/report_period_type.dart';
// import '../../domain/models/representative_report_model.dart';
// import '../../domain/report_pdf_builder.dart';
// import '../cubit/daily_report_cubit.dart';
// import '../cubit/daily_report_state.dart';

// class DailyReportScreen extends StatelessWidget {
//   final String? selectedRepId;

//   const DailyReportScreen({super.key, this.selectedRepId});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => DailyReportCubit(
//         sl(),
//         ownerSelectedRepId: selectedRepId,
//       )..load(),
//       child: const _DailyReportBody(),
//     );
//   }
// }

// class _DailyReportBody extends StatelessWidget {
//   const _DailyReportBody();

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     final dummyReport = RepresentativeReportModel(
//       from: DateTime.now(),
//       to: DateTime.now(),
//       repId: '123',
//       totalSales: 15000,
//       invoiceCount: 20,
//       totalCollections: 12000,
//       collectionsByMethod: const {'cash': 5000, 'vodafone_cash': 7000},
//       collectionsByCustomer: const [
//         CustomerCollectionModel(
//             customerName: 'محمد أحمد',
//             totalCollected: 5000,
//             breakdown: {'cash': 5000}),
//         CustomerCollectionModel(
//             customerName: 'محمود علي',
//             totalCollected: 7000,
//             breakdown: {'vodafone_cash': 7000}),
//       ],
//       salesByCustomer: const [],
//       expenses: [
//         ExpenseItemModel(
//             category: 'بنزين',
//             amount: 200,
//             paymentMethod: 'cash',
//             expenseAt: DateTime.now())
//       ],
//       totalExpenses: 200,
//       expensesByMethod: const {'cash': 200},
//       balances: const {'cash': 4800, 'vodafone_cash': 7000, 'instapay': 0},
//     );

//     return Scaffold(
//       backgroundColor: colors.background,
//       appBar: AppBar(
//         title: Text('التقارير',
//             style: AppTextStyles.cairoBold18.copyWith(color: colors.text)),
//         backgroundColor: colors.surface,
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: IconThemeData(color: colors.text),
//       ),
//       body: SafeArea(
//         child: BlocBuilder<DailyReportCubit, DailyReportState>(
//           builder: (context, state) {
//             if (state is DailyReportError) {
//               return Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.error_outline_rounded,
//                         size: 48.sp, color: AppColors.statusNotReached),
//                     SizedBox(height: 16.h),
//                     Text(state.message,
//                         style: AppTextStyles.cairoMedium16
//                             .copyWith(color: colors.textMuted)),
//                     SizedBox(height: 16.h),
//                     ElevatedButton.icon(
//                       onPressed: () => context.read<DailyReportCubit>().load(),
//                       icon: const Icon(Icons.refresh_rounded,
//                           color: Colors.white),
//                       label: const Text('إعادة المحاولة',
//                           style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryGreen,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12.r)),
//                         padding: EdgeInsets.symmetric(
//                             horizontal: 24.w, vertical: 12.h),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             final isLoading = state is! DailyReportLoaded;
//             final report =
//                 state is DailyReportLoaded ? state.report : dummyReport;
//             final selectedPeriod = state is DailyReportLoaded
//                 ? state.selectedPeriod
//                 : ReportPeriodType.daily;

//             return RefreshIndicator(
//               color: AppColors.primaryGreen,
//               onRefresh: () => context.read<DailyReportCubit>().refresh(),
//               child: Skeletonizer(
//                 enabled: isLoading,
//                 child: ListView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: EdgeInsets.all(16.w),
//                   children: [
//                     _AnimatedPeriodSelector(
//                       selected: selectedPeriod,
//                       onChanged: (p) {
//                         if (!isLoading) {
//                           context.read<DailyReportCubit>().selectPeriod(p);
//                         }
//                       },
//                     ),
//                     SizedBox(height: 20.h),
//                     _SummarySection(report: report),
//                     SizedBox(height: 16.h),
//                     _BalancesSection(report: report),
//                     SizedBox(height: 16.h),
//                     _CollectionsSection(report: report),
//                     SizedBox(height: 16.h),
//                     _ExpensesSection(report: report),
//                     SizedBox(height: 24.h),
//                     if (!isLoading) _ExportButtons(report: report),
//                     SizedBox(height: 24.h),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedPeriodSelector extends StatelessWidget {
//   final ReportPeriodType selected;
//   final ValueChanged<ReportPeriodType> onChanged;

//   const _AnimatedPeriodSelector({
//     required this.selected,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final tabWidth = constraints.maxWidth / 3;
//         final selectedIndex = ReportPeriodType.values.indexOf(selected);

//         return Container(
//           height: 52.h,
//           decoration: BoxDecoration(
//             color: context.colors.border.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(14.r),
//           ),
//           child: Stack(
//             children: [
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.fastOutSlowIn,
//                 top: 4.h,
//                 bottom: 4.h,
//                 right: tabWidth * selectedIndex + 4.w,
//                 width: tabWidth - 8.w,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryGreen,
//                     borderRadius: BorderRadius.circular(10.r),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.primaryGreen.withOpacity(0.25),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Row(
//                 children: ReportPeriodType.values.map((period) {
//                   final isSelected = selected == period;
//                   return Expanded(
//                     child: GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: () => onChanged(period),
//                       child: Center(
//                         child: AnimatedDefaultTextStyle(
//                           duration: const Duration(milliseconds: 300),
//                           style: AppTextStyles.cairoMedium16.copyWith(
//                             color: isSelected
//                                 ? Colors.white
//                                 : context.colors.textMuted,
//                             fontSize: 14.sp,
//                             fontWeight:
//                                 isSelected ? FontWeight.w700 : FontWeight.w500,
//                           ),
//                           child: Text(period.label),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _BaseCard extends StatelessWidget {
//   final String title;
//   final Widget child;
//   final IconData? icon;

//   const _BaseCard({required this.title, required this.child, this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(20.w),
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         borderRadius: BorderRadius.circular(16.r),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.04),
//             blurRadius: 15,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: context.colors.border.withOpacity(0.5)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               if (icon != null) ...[
//                 Container(
//                   padding: EdgeInsets.all(6.w),
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryGreen.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                   child: Icon(icon, color: AppColors.primaryGreen, size: 20.w),
//                 ),
//                 SizedBox(width: 10.w),
//               ],
//               Text(
//                 title,
//                 style: AppTextStyles.cairoBold18.copyWith(
//                   fontSize: 16.sp,
//                   color: context.colors.text,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           child,
//         ],
//       ),
//     );
//   }
// }

// class _SummarySection extends StatelessWidget {
//   final RepresentativeReportModel report;

//   const _SummarySection({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(20.w),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             AppColors.primary,
//             AppColors.secondary,
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16.r),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.2),
//             blurRadius: 15,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(6.w),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//                 child: Icon(Icons.analytics_outlined,
//                     color: Colors.white, size: 20.w),
//               ),
//               SizedBox(width: 10.w),
//               Text(
//                 'ملخص التقرير',
//                 style: AppTextStyles.cairoBold18.copyWith(
//                   fontSize: 16.sp,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 24.h),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildItem('إجمالي المبيعات', report.totalSales),
//               _buildItem('إجمالي التحصيل', report.totalCollections),
//             ],
//           ),
//           SizedBox(height: 20.h),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildItem('عدد الفواتير', report.invoiceCount.toDouble(),
//                   isCount: true),
//               _buildItem('إجمالي المصروفات', report.totalExpenses),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildItem(String label, double value, {bool isCount = false}) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: AppTextStyles.almaraiRegular14.copyWith(
//               color: Colors.white70,
//               fontSize: 12.sp,
//             ),
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             isCount
//                 ? value.toInt().toString()
//                 : '${value.toStringAsFixed(2)} ج.م',
//             style: AppTextStyles.cairoBold18.copyWith(
//               fontSize: 16.sp,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BalancesSection extends StatelessWidget {
//   final RepresentativeReportModel report;

//   const _BalancesSection({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return _BaseCard(
//       title: 'الأرصدة الحالية',
//       icon: Icons.account_balance_wallet_outlined,
//       child: Column(
//         children: [
//           _buildBalanceRow('cash', 'كاش', Icons.money, context),
//           _buildDivider(context),
//           _buildBalanceRow('vodafone_cash', 'فودافون كاش', null, context,
//               imagePath: AppImages.vodafoneCash),
//           _buildDivider(context),
//           _buildBalanceRow('instapay', 'InstaPay', null, context,
//               imagePath: AppImages.instaPay),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 8.h),
//       child: Divider(color: context.colors.border.withOpacity(0.5), height: 1),
//     );
//   }

//   Widget _buildBalanceRow(
//       String key, String title, IconData? icon, BuildContext context,
//       {String? imagePath}) {
//     final balance = report.balances[key] ?? 0.0;
//     return Row(
//       children: [
//         if (icon != null)
//           Container(
//             padding: EdgeInsets.all(6.w),
//             decoration: BoxDecoration(
//               color: context.colors.border.withOpacity(0.3),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: AppColors.primaryGreen, size: 20.w),
//           ),
//         if (imagePath != null)
//           Container(
//             padding: EdgeInsets.all(6.w),
//             decoration: BoxDecoration(
//               color: context.colors.border.withOpacity(0.3),
//               shape: BoxShape.circle,
//             ),
//             child: Image.asset(imagePath, width: 20.w, height: 20.w),
//           ),
//         SizedBox(width: 12.w),
//         Text(title,
//             style: AppTextStyles.cairoMedium16.copyWith(
//                 fontSize: 14.sp,
//                 color: context.colors.text,
//                 fontWeight: FontWeight.w600)),
//         const Spacer(),
//         Text('${balance.toStringAsFixed(2)} ج.م',
//             style: AppTextStyles.cairoBold18.copyWith(
//                 fontSize: 15.sp,
//                 color: context.colors.text,
//                 fontWeight: FontWeight.w800)),
//       ],
//     );
//   }
// }

// class _CollectionsSection extends StatelessWidget {
//   final RepresentativeReportModel report;

//   const _CollectionsSection({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return _BaseCard(
//       title: 'تحصيلات العملاء',
//       icon: Icons.people_outline_rounded,
//       child: report.collectionsByCustomer.isEmpty
//           ? Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 16.h),
//                 child: Text('لا توجد تحصيلات',
//                     style: AppTextStyles.cairoMedium16
//                         .copyWith(color: context.colors.textMuted)),
//               ),
//             )
//           : ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: report.collectionsByCustomer.length,
//               separatorBuilder: (context, index) => Padding(
//                 padding: EdgeInsets.symmetric(vertical: 12.h),
//                 child: Divider(
//                     color: context.colors.border.withOpacity(0.5), height: 1),
//               ),
//               itemBuilder: (context, index) {
//                 final c = report.collectionsByCustomer[index];
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(c.customerName,
//                             style: AppTextStyles.cairoMedium16.copyWith(
//                                 fontSize: 14.sp, color: context.colors.text)),
//                         Text('${c.totalCollected.toStringAsFixed(2)} ج.م',
//                             style: AppTextStyles.cairoBold18.copyWith(
//                                 fontSize: 14.sp,
//                                 color: AppColors.primaryGreen)),
//                       ],
//                     ),
//                     SizedBox(height: 6.h),
//                     Wrap(
//                       spacing: 12.w,
//                       runSpacing: 4.h,
//                       children: [
//                         if (c.breakdown['cash'] != null &&
//                             c.breakdown['cash']! > 0)
//                           _buildMethodTag('كاش', c.breakdown['cash']!, context),
//                         if (c.breakdown['vodafone_cash'] != null &&
//                             c.breakdown['vodafone_cash']! > 0)
//                           _buildMethodTag('فودافون كاش',
//                               c.breakdown['vodafone_cash']!, context),
//                         if (c.breakdown['instapay'] != null &&
//                             c.breakdown['instapay']! > 0)
//                           _buildMethodTag(
//                               'InstaPay', c.breakdown['instapay']!, context),
//                       ],
//                     )
//                   ],
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildMethodTag(String name, double amount, BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//       decoration: BoxDecoration(
//         color: context.colors.border.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(6.r),
//       ),
//       child: Text(
//         '$name: ${amount.toStringAsFixed(2)}',
//         style: AppTextStyles.almaraiRegular14
//             .copyWith(fontSize: 11.sp, color: context.colors.text),
//       ),
//     );
//   }
// }

// class _ExpensesSection extends StatelessWidget {
//   final RepresentativeReportModel report;

//   const _ExpensesSection({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return _BaseCard(
//       title: 'المصروفات',
//       icon: Icons.money_off_csred_outlined,
//       child: report.expenses.isEmpty
//           ? Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 16.h),
//                 child: Text('لا توجد مصروفات',
//                     style: AppTextStyles.cairoMedium16
//                         .copyWith(color: context.colors.textMuted)),
//               ),
//             )
//           : ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: report.expenses.length,
//               separatorBuilder: (context, index) => Padding(
//                 padding: EdgeInsets.symmetric(vertical: 12.h),
//                 child: Divider(
//                     color: context.colors.border.withOpacity(0.5), height: 1),
//               ),
//               itemBuilder: (context, index) {
//                 final e = report.expenses[index];
//                 return Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(e.category,
//                               style: AppTextStyles.cairoMedium16.copyWith(
//                                   fontSize: 14.sp, color: context.colors.text)),
//                           if (e.notes != null && e.notes!.isNotEmpty) ...[
//                             SizedBox(height: 2.h),
//                             Text(e.notes!,
//                                 style: AppTextStyles.almaraiRegular14.copyWith(
//                                     fontSize: 12.sp,
//                                     color: context.colors.textMuted)),
//                           ]
//                         ],
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text('${e.amount.toStringAsFixed(2)} ج.م',
//                             style: AppTextStyles.cairoBold18.copyWith(
//                                 fontSize: 14.sp,
//                                 color: AppColors.statusNotReached)),
//                         SizedBox(height: 2.h),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: 6.w, vertical: 2.h),
//                           decoration: BoxDecoration(
//                             color: context.colors.border.withOpacity(0.4),
//                             borderRadius: BorderRadius.circular(4.r),
//                           ),
//                           child: Text(_formatMethod(e.paymentMethod),
//                               style: AppTextStyles.almaraiRegular14.copyWith(
//                                   fontSize: 10.sp,
//                                   color: context.colors.textMuted)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 );
//               },
//             ),
//     );
//   }

//   String _formatMethod(String method) {
//     switch (method) {
//       case 'cash':
//         return 'كاش';
//       case 'vodafone_cash':
//         return 'فودافون كاش';
//       case 'instapay':
//         return 'InstaPay';
//       default:
//         return method;
//     }
//   }
// }

// class _ExportButtons extends StatelessWidget {
//   final RepresentativeReportModel report;

//   const _ExportButtons({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Material(
//             color: AppColors.primary,
//             borderRadius: BorderRadius.circular(14.r),
//             elevation: 4,
//             shadowColor: AppColors.primary.withOpacity(0.3),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(14.r),
//               onTap: () async {
//                 final bytes = await ReportPdfBuilder.build(report);
//                 await Printing.layoutPdf(onLayout: (_) async => bytes);
//               },
//               child: Container(
//                 alignment: Alignment.center,
//                 padding: EdgeInsets.symmetric(vertical: 14.h),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.print_outlined,
//                         color: Colors.white, size: 18.sp),
//                     SizedBox(width: 8.w),
//                     Text('طباعة',
//                         style: AppTextStyles.cairoMedium16
//                             .copyWith(color: Colors.white, fontSize: 14.sp)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(width: 12.w),
//         Expanded(
//           child: Material(
//             color: context.colors.surface,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14.r),
//               side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
//             ),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(14.r),
//               onTap: () async {
//                 final bytes = await ReportPdfBuilder.build(report);
//                 await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
//               },
//               child: Container(
//                 alignment: Alignment.center,
//                 padding: EdgeInsets.symmetric(vertical: 14.h),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.ios_share_rounded,
//                         color: AppColors.primary, size: 18.sp),
//                     SizedBox(width: 8.w),
//                     Text('تصدير PDF',
//                         style: AppTextStyles.cairoMedium16.copyWith(
//                             color: AppColors.primary, fontSize: 14.sp)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/const/app_images.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_color_scheme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_extension.dart';
import '../../../home/presentation/widgets/add_expense_dialog.dart';
import '../../domain/models/report_period_type.dart';
import '../../domain/models/representative_report_model.dart';
import '../../domain/report_pdf_builder.dart';
import '../cubit/daily_report_cubit.dart';
import '../cubit/daily_report_state.dart';

class DailyReportScreen extends StatelessWidget {
  final String? selectedRepId;

  const DailyReportScreen({super.key, this.selectedRepId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailyReportCubit(
        sl(),
        ownerSelectedRepId: selectedRepId,
      )..load(),
      child: const _DailyReportBody(),
    );
  }
}

class _DailyReportBody extends StatelessWidget {
  const _DailyReportBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final dummyReport = RepresentativeReportModel(
      from: DateTime.now(),
      to: DateTime.now(),
      repId: '123',
      totalSales: 15000,
      invoiceCount: 20,
      totalCollections: 12000,
      collectionsByMethod: const {'cash': 5000, 'vodafone_cash': 7000},
      collectionsByCustomer: const [
        CustomerCollectionModel(
            customerName: 'محمد أحمد',
            totalCollected: 5000,
            breakdown: {'cash': 5000}),
        CustomerCollectionModel(
            customerName: 'محمود علي',
            totalCollected: 7000,
            breakdown: {'vodafone_cash': 7000}),
      ],
      salesByCustomer: const [],
      expenses: [
        ExpenseItemModel(
            category: 'بنزين',
            amount: 200,
            paymentMethod: 'cash',
            expenseAt: DateTime.now())
      ],
      totalExpenses: 200,
      expensesByMethod: const {'cash': 200},
      balances: const {
        'cash': PaymentMethodBalanceModel(
            beforeExpenses: 5000, expenses: 200, afterExpenses: 4800),
        'vodafone_cash': PaymentMethodBalanceModel(
            beforeExpenses: 7000, expenses: 0, afterExpenses: 7000),
        'instapay': PaymentMethodBalanceModel(
            beforeExpenses: 0, expenses: 0, afterExpenses: 0),
      },
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('التقارير',
            style: AppTextStyles.cairoBold18.copyWith(color: colors.text)),
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.add_card_rounded,
                color: AppColors.primaryGreen, size: 24.w),
            onPressed: () async {
              final added = await showDialog<bool>(
                context: context,
                builder: (_) => const AddExpenseDialog(),
              );
              if (added == true && context.mounted) {
                context.read<DailyReportCubit>().refresh();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DailyReportCubit, DailyReportState>(
          builder: (context, state) {
            if (state is DailyReportError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48.sp, color: AppColors.statusNotReached),
                    SizedBox(height: 16.h),
                    Text(state.message,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.textMuted)),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () => context.read<DailyReportCubit>().load(),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      label: const Text('إعادة المحاولة',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                      ),
                    ),
                  ],
                ),
              );
            }

            final isLoading = state is! DailyReportLoaded;
            final report =
                state is DailyReportLoaded ? state.report : dummyReport;
            final selectedPeriod = state is DailyReportLoaded
                ? state.selectedPeriod
                : ReportPeriodType.daily;

            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<DailyReportCubit>().refresh(),
              child: Skeletonizer(
                enabled: isLoading,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  children: [
                    _AnimatedPeriodSelector(
                      selected: selectedPeriod,
                      onChanged: (p) {
                        if (!isLoading) {
                          context.read<DailyReportCubit>().selectPeriod(p);
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    _SummarySection(report: report),
                    SizedBox(height: 16.h),
                    _BalancesSection(report: report),
                    SizedBox(height: 16.h),
                    _CollectionsSection(report: report),
                    SizedBox(height: 16.h),
                    _ExpensesSection(report: report),
                    SizedBox(height: 24.h),
                    if (!isLoading) _ExportButtons(report: report),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedPeriodSelector extends StatelessWidget {
  final ReportPeriodType selected;
  final ValueChanged<ReportPeriodType> onChanged;

  const _AnimatedPeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / 3;
        final selectedIndex = ReportPeriodType.values.indexOf(selected);

        return Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: context.colors.border.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                top: 4.h,
                bottom: 4.h,
                right: tabWidth * selectedIndex + 4.w,
                width: tabWidth - 8.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: ReportPeriodType.values.map((period) {
                  final isSelected = selected == period;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(period),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: isSelected
                                ? Colors.white
                                : context.colors.textMuted,
                            fontSize: 14.sp,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(period.label),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BaseCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const _BaseCard({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: AppColors.primaryGreen, size: 20.w),
                ),
                SizedBox(width: 10.w),
              ],
              Text(
                title,
                style: AppTextStyles.cairoBold18.copyWith(
                  fontSize: 16.sp,
                  color: context.colors.text,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final RepresentativeReportModel report;

  const _SummarySection({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 20.w),
              ),
              SizedBox(width: 10.w),
              Text(
                'ملخص التقرير',
                style: AppTextStyles.cairoBold18.copyWith(
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItem('إجمالي المبيعات', report.totalSales),
              _buildItem('إجمالي التحصيل', report.totalCollections),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItem('عدد الفواتير', report.invoiceCount.toDouble(),
                  isCount: true),
              _buildItem('إجمالي المصروفات', report.totalExpenses),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, double value, {bool isCount = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isCount
                ? value.toInt().toString()
                : '${value.toStringAsFixed(2)} ج.م',
            style: AppTextStyles.cairoBold18.copyWith(
              fontSize: 16.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancesSection extends StatelessWidget {
  final RepresentativeReportModel report;

  const _BalancesSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'الأرصدة الحالية',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _buildBalanceRow('cash', 'كاش', Icons.money, context),
          _buildDivider(context),
          _buildBalanceRow('vodafone_cash', 'فودافون كاش', null, context,
              imagePath: AppImages.vodafoneCash),
          _buildDivider(context),
          _buildBalanceRow('instapay', 'InstaPay', null, context,
              imagePath: AppImages.instaPay),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Divider(color: context.colors.border.withOpacity(0.5), height: 1),
    );
  }

  Widget _buildBalanceRow(
      String key, String title, IconData? icon, BuildContext context,
      {String? imagePath}) {
    final balanceModel = report.balances[key] ??
        const PaymentMethodBalanceModel(
            beforeExpenses: 0, expenses: 0, afterExpenses: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: context.colors.border.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 18.w),
              ),
            if (imagePath != null)
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: context.colors.border.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(imagePath, width: 18.w, height: 18.w),
              ),
            SizedBox(width: 10.w),
            Text(title,
                style: AppTextStyles.cairoBold18
                    .copyWith(fontSize: 14.sp, color: context.colors.text)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildBalanceValue(context, 'قبل المصروفات',
                  balanceModel.beforeExpenses, context.colors.textMuted),
            ),
            Container(
                width: 1,
                height: 30.h,
                color: context.colors.border.withOpacity(0.5)),
            Expanded(
              child: _buildBalanceValue(context, 'المصروفات',
                  balanceModel.expenses, AppColors.statusNotReached),
            ),
            Container(
                width: 1,
                height: 30.h,
                color: context.colors.border.withOpacity(0.5)),
            Expanded(
              child: _buildBalanceValue(context, 'بعد المصروفات',
                  balanceModel.afterExpenses, context.colors.text),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceValue(
      BuildContext context, String label, double value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(fontSize: 10.sp, color: context.colors.textMuted)),
        SizedBox(height: 4.h),
        Text('${value.toStringAsFixed(2)} ج.م',
            style: AppTextStyles.cairoBold18
                .copyWith(fontSize: 12.sp, color: valueColor)),
      ],
    );
  }
}

class _CollectionsSection extends StatelessWidget {
  final RepresentativeReportModel report;

  const _CollectionsSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'تحصيلات العملاء',
      icon: Icons.people_outline_rounded,
      child: report.collectionsByCustomer.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text('لا توجد تحصيلات',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: context.colors.textMuted)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.collectionsByCustomer.length,
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Divider(
                    color: context.colors.border.withOpacity(0.5), height: 1),
              ),
              itemBuilder: (context, index) {
                final c = report.collectionsByCustomer[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.customerName,
                            style: AppTextStyles.cairoMedium16.copyWith(
                                fontSize: 14.sp, color: context.colors.text)),
                        Text('${c.totalCollected.toStringAsFixed(2)} ج.م',
                            style: AppTextStyles.cairoBold18.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.primaryGreen)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 4.h,
                      children: [
                        if (c.breakdown['cash'] != null &&
                            c.breakdown['cash']! > 0)
                          _buildMethodTag('كاش', c.breakdown['cash']!, context),
                        if (c.breakdown['vodafone_cash'] != null &&
                            c.breakdown['vodafone_cash']! > 0)
                          _buildMethodTag('فودافون كاش',
                              c.breakdown['vodafone_cash']!, context),
                        if (c.breakdown['instapay'] != null &&
                            c.breakdown['instapay']! > 0)
                          _buildMethodTag(
                              'InstaPay', c.breakdown['instapay']!, context),
                      ],
                    )
                  ],
                );
              },
            ),
    );
  }

  Widget _buildMethodTag(String name, double amount, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.colors.border.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$name: ${amount.toStringAsFixed(2)}',
        style: AppTextStyles.almaraiRegular14
            .copyWith(fontSize: 11.sp, color: context.colors.text),
      ),
    );
  }
}

class _ExpensesSection extends StatelessWidget {
  final RepresentativeReportModel report;

  const _ExpensesSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'المصروفات',
      icon: Icons.money_off_csred_outlined,
      child: report.expenses.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text('لا توجد مصروفات',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: context.colors.textMuted)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.expenses.length,
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Divider(
                    color: context.colors.border.withOpacity(0.5), height: 1),
              ),
              itemBuilder: (context, index) {
                final e = report.expenses[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.category,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                  fontSize: 14.sp, color: context.colors.text)),
                          if (e.notes != null && e.notes!.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(e.notes!,
                                style: AppTextStyles.almaraiRegular14.copyWith(
                                    fontSize: 12.sp,
                                    color: context.colors.textMuted)),
                          ]
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${e.amount.toStringAsFixed(2)} ج.م',
                            style: AppTextStyles.cairoBold18.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.statusNotReached)),
                        SizedBox(height: 2.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: context.colors.border.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(_formatMethod(e.paymentMethod),
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                  fontSize: 10.sp,
                                  color: context.colors.textMuted)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatMethod(String method) {
    switch (method) {
      case 'cash':
        return 'كاش';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'InstaPay';
      default:
        return method;
    }
  }
}

class _ExportButtons extends StatelessWidget {
  final RepresentativeReportModel report;

  const _ExportButtons({required this.report});

  @override
  Widget build(BuildContext context) {
    // navy in light mode, light gray in dark mode — AppColors.primary (navy)
    // is invisible on the dark surface.
    final exportColor = context.colors.text;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14.r),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
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
                            .copyWith(color: Colors.white, fontSize: 14.sp)),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Material(
            color: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(color: exportColor.withOpacity(0.25)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () async {
                final bytes = await ReportPdfBuilder.build(report);
                await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ios_share_rounded,
                        color: exportColor, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text('تصدير PDF',
                        style: AppTextStyles.cairoMedium16.copyWith(
                            color: exportColor, fontSize: 14.sp)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
