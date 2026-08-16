import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/mock_customers_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/customer_detail_screen.dart';
import '../../domain/models/app_notification_model.dart';
import '../../domain/notification_repository.dart';
import 'notification_time_label.dart';
import 'notification_type_style.dart';

class NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onDeleted;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onDeleted,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (!notification.isRead) {
      await NotificationRepository.instance.markAsRead(notification.id);
    }

    final relatedId = notification.relatedId;
    if (relatedId == null) return;

    final customer =
        MockCustomersRepository.instance.getCustomerById(relatedId);
    if (customer == null || customer.id.isEmpty || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = notificationTypeColor(context, notification.type);
    final icon = notificationTypeIcon(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: context.colors.statusNotReached.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: context.colors.statusNotReached,
          size: 18.sp,
        ),
      ),
      onDismissed: (_) {
        NotificationRepository.instance.remove(notification.id);
        onDeleted();
      },
      child: Material(
        color: notification.isRead
            ? context.colors.surface
            : color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _handleTap(context),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: notification.isRead
                    ? context.colors.border
                    : color.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: HugeIcon(icon: icon, color: color, size: 18.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                color: context.colors.text,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              margin: EdgeInsets.only(right: 6.w),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            notificationTimeLabel(notification.createdAt),
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: context.colors.textMuted,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        notification.message,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
