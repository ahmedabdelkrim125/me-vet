import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';

void showRouteReportSheet(BuildContext context, List<RouteStopModel> stops) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RouteReportSheet(stops: stops),
  );
}

class _RouteReportSheet extends StatelessWidget {
  final List<RouteStopModel> stops;

  const _RouteReportSheet({required this.stops});

  int _countOf(RouteVisitStatus status) =>
      stops.where((s) => s.status == status).length;

  @override
  Widget build(BuildContext context) {
    final completed =
        _countOf(RouteVisitStatus.completed) + _countOf(RouteVisitStatus.sold);
    final sold = _countOf(RouteVisitStatus.sold);
    final noOrder = _countOf(RouteVisitStatus.noOrder);
    final notReached = _countOf(RouteVisitStatus.notReached);
    final pending = _countOf(RouteVisitStatus.pending);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 14.h),
          Text('تقرير الخط',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: AppColors.primary, fontSize: 16.sp)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'إجمالي الزيارات',
                      value: '${stops.length}',
                      color: AppColors.primary)),
              SizedBox(width: 10.w),
              Expanded(
                  child: _StatBox(
                      label: 'تمت',
                      value: '$completed',
                      color: AppColors.primaryGreen)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'بيع', value: '$sold', color: AppColors.statBlue)),
              SizedBox(width: 10.w),
              Expanded(
                  child: _StatBox(
                      label: 'بدون طلب',
                      value: '$noOrder',
                      color: AppColors.statOrange)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      label: 'لم يوصل',
                      value: '$notReached',
                      color: AppColors.statusNotReached)),
              SizedBox(width: 10.w),
              Expanded(
                  child: _StatBox(
                      label: 'لسه',
                      value: '$pending',
                      color: AppColors.navInactive)),
            ],
          ),
          SizedBox(height: 18.h),
          Text('تفاصيل الزيارات',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: AppColors.primary, fontSize: 13.sp)),
          SizedBox(height: 8.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 260.h),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: stops.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final stop = stops[index];
                return Row(
                  children: [
                    Expanded(
                      child: Text(stop.customerName,
                          style: AppTextStyles.cairoMedium16.copyWith(
                              color: AppColors.primary, fontSize: 12.sp)),
                    ),
                    Text(stop.status.label,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                            color: AppColors.navInactive, fontSize: 11.sp)),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          Material(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {},
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.paperplane_fill,
                        color: Colors.white, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text('إرسال التقرير للإدارة',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: Colors.white, fontSize: 13.sp)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.cairoBold18
                  .copyWith(color: color, fontSize: 18.sp)),
          SizedBox(height: 4.h),
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: AppColors.navInactive, fontSize: 10.sp)),
        ],
      ),
    );
  }
}
