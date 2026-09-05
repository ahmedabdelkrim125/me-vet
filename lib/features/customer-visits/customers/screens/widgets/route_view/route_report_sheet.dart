import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../../../core/theme/app_color_scheme_extension.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import 'route_status_style.dart';

Future<void> showRouteReportSheet(
  BuildContext context,
  List<RouteStopModel> stops,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RouteReportSheet(stops: stops),
  );
}

class _RouteReportSheet extends StatelessWidget {
  final List<RouteStopModel> stops;

  const _RouteReportSheet({required this.stops});

  int _countFor(RouteVisitStatus status) =>
      stops.where((s) => s.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 560.h),
      decoration: BoxDecoration(
        color: context.colors.background,
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'تقرير الخط',
            style: AppTextStyles.cairoBold18
                .copyWith(color: context.colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final status in RouteVisitStatus.values)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: routeStatusColor(context, status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${status.label}: ${_countFor(status)}',
                    style: AppTextStyles.cairoMedium16.copyWith(
                        color: routeStatusColor(context, status),
                        fontSize: 11.sp),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: stops.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final stop = stops[index];
                final color = routeStatusColor(context, stop.status);
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.customerName,
                          style: AppTextStyles.cairoMedium16.copyWith(
                              color: context.colors.text, fontSize: 12.sp),
                        ),
                      ),
                      Text(
                        stop.status.label,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: color, fontSize: 11.sp),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
