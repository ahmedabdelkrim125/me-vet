import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import 'route_status_style.dart';

Future<void> showIncompleteRouteCustomersSheet(
  BuildContext context, {
  required List<RouteStopModel> stops,
  required Future<void> Function(DateTime targetDay) onCarryToDay,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _IncompleteRouteCustomersSheet(
      stops: stops,
      onCarryToDay: onCarryToDay,
    ),
  );
}

class _IncompleteRouteCustomersSheet extends StatelessWidget {
  final List<RouteStopModel> stops;
  final Future<void> Function(DateTime targetDay) onCarryToDay;

  const _IncompleteRouteCustomersSheet({
    required this.stops,
    required this.onCarryToDay,
  });

  Future<void> _pickDayAndCarry(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'اختار اليوم اللي تحب ترحّلهم ليه',
    );
    if (picked == null) return;
    await onCarryToDay(picked);
    if (context.mounted) Navigator.of(context).pop();
  }

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
            'عملاء لم تتم زيارتهم',
            style: AppTextStyles.cairoBold18
                .copyWith(color: context.colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            stops.isEmpty
                ? 'كل زيارات خط اليوم مكتملة'
                : '${stops.length} عميل ممكن ترحيلهم لليوم التالي',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: context.colors.textMuted, fontSize: 12.sp),
          ),
          SizedBox(height: 14.h),
          Flexible(
            child: stops.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 34.h),
                      child: Text(
                        'مفيش عملاء متبقين في خط اليوم',
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      final color = routeStatusColor(context, stop.status);

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.customerName,
                                    style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.text,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    stop.area,
                                    style:
                                        AppTextStyles.almaraiRegular14.copyWith(
                                      color: context.colors.textMuted,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                stop.status.label,
                                style: AppTextStyles.cairoMedium16.copyWith(
                                  color: color,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (stops.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Material(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(14.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => _pickDayAndCarry(context),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: Text(
                    'ترحيل غير المكتمل ليوم تاني',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: Colors.white, fontSize: 13.sp),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
