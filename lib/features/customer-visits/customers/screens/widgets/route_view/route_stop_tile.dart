import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import 'route_status_style.dart';

class RouteStopTile extends StatelessWidget {
  final RouteStopModel stop;
  final bool isLast;
  final int index;
  final VoidCallback onTap;

  const RouteStopTile({
    super.key,
    required this.stop,
    required this.isLast,
    required this.index,
    required this.onTap,
  });

  bool get _isDone =>
      stop.status == RouteVisitStatus.completed ||
      stop.status == RouteVisitStatus.sold;

  @override
  Widget build(BuildContext context) {
    final color = routeStatusColor(context, stop.status);
    final lineColor = _isDone ? context.colors.primary : context.colors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                width: 32.w,
                height: 32.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.4),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _isDone
                      ? HugeIcon(
                          key: const ValueKey('done'),
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 16.sp,
                          color: color,
                        )
                      : Text(
                          '${stop.order}',
                          key: const ValueKey('pending'),
                          style: AppTextStyles.cairoBold18.copyWith(
                            color: color,
                            fontSize: 12.sp,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: onTap,
                child: Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 18.sp,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.customerName,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                color: context.colors.text,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  size: 12.sp,
                                  color: context.colors.textMuted,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  stop.area,
                                  style:
                                      AppTextStyles.almaraiRegular14.copyWith(
                                    color: context.colors.textMuted,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(stop.status),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            stop.status.label,
                            style: AppTextStyles.cairoMedium16.copyWith(
                              color: color,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
