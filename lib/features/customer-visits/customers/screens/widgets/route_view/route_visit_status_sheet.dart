import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import '../../customer_detail_screen.dart';
import 'route_status_style.dart';

Future<void> showRouteStopActionsSheet(
  BuildContext context, {
  required RouteStopModel stop,
  required ValueChanged<RouteVisitStatus> onStatusChanged,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RouteStopActionsSheet(
      stop: stop,
      onStatusChanged: onStatusChanged,
      onRemove: onRemove,
    ),
  );
}

class _RouteStopActionsSheet extends StatelessWidget {
  final RouteStopModel stop;
  final ValueChanged<RouteVisitStatus> onStatusChanged;
  final VoidCallback onRemove;

  const _RouteStopActionsSheet({
    required this.stop,
    required this.onStatusChanged,
    required this.onRemove,
  });

  static const _statuses = [
    RouteVisitStatus.pending,
    RouteVisitStatus.completed,
    RouteVisitStatus.sold,
    RouteVisitStatus.noOrder,
    RouteVisitStatus.notReached,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            stop.customerName,
            style: AppTextStyles.cairoBold18
                .copyWith(color: context.colors.text, fontSize: 16.sp),
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
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: context.colors.textMuted, fontSize: 11.sp),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'حالة الزيارة',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: context.colors.text, fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          for (final status in _statuses)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _StatusOption(
                status: status,
                isSelected: stop.status == status,
                onTap: () {
                  onStatusChanged(status);
                  Navigator.of(context).pop();
                },
              ),
            ),
          SizedBox(height: 6.h),
          Material(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                final customer = MockCustomersRepository.instance
                    .getCustomerById(stop.customerId);
                Navigator.of(context).pop();
                if (customer == null || customer.id.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customer: customer),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  'فتح ملف العميل الكامل',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: context.colors.text, fontSize: 13.sp),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Material(
            color: context.colors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                onRemove();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                alignment: Alignment.center,
                child: Text(
                  'إزالة من خط اليوم',
                  style: AppTextStyles.cairoMedium16.copyWith(
                      color: context.colors.statusNotReached, fontSize: 13.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final RouteVisitStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = routeStatusColor(context, status);

    return Material(
      color: isSelected ? color.withOpacity(0.1) : context.colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? color : context.colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.14),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: isSelected
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 12.sp,
                        color: color,
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Text(
                status.label,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
