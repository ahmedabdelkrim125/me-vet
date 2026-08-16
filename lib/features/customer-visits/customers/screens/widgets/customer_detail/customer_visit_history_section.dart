import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/visit_status.dart';
import '../../../domain/models/visit_history_model.dart';
import '../../../domain/today_route_controller.dart';
import '../route_view/route_status_style.dart';

class CustomerVisitHistorySection extends StatefulWidget {
  final String customerId;

  const CustomerVisitHistorySection({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerVisitHistorySection> createState() =>
      _CustomerVisitHistorySectionState();
}

class _CustomerVisitHistorySectionState
    extends State<CustomerVisitHistorySection> {
  final TodayRouteController _routeController = TodayRouteController.instance;

  @override
  void initState() {
    super.initState();
    _routeController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<VisitHistoryModel>>(
      valueListenable: _routeController.visitHistoryNotifier,
      builder: (context, _, __) {
        final visits = _routeController.visitsForCustomer(widget.customerId);

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تاريخ الزيارات',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: context.colors.text,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
              if (visits.isEmpty)
                Text(
                  'مفيش زيارات مسجلة للعميل ده حتى الآن',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 12.sp,
                  ),
                )
              else
                for (int i = 0; i < visits.length; i++) ...[
                  _VisitHistoryRow(visit: visits[i]),
                  if (i != visits.length - 1) SizedBox(height: 10.h),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _VisitHistoryRow extends StatelessWidget {
  final VisitHistoryModel visit;

  const _VisitHistoryRow({required this.visit});

  @override
  Widget build(BuildContext context) {
    final color = routeStatusColor(context, visit.status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.colors.background,
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
                  _formatDateTime(visit.scheduledAt),
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: context.colors.text,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'آخر تحديث: ${_formatTime(visit.statusUpdatedAt)} - ${visit.area}',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              visit.status.label,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: color,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$year/$month/$day - ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
