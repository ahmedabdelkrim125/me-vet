import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/models/app_notification_model.dart';
import '../../domain/notification_repository.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    NotificationRepository.instance.initialize();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<AppNotificationModel>>(
          valueListenable:
              NotificationRepository.instance.notificationsNotifier,
          builder: (context, notifications, _) {
            final todayItems =
                notifications.where((n) => _isToday(n.createdAt)).toList();
            final earlierItems =
                notifications.where((n) => !_isToday(n.createdAt)).toList();
            final hasUnread = notifications.any((n) => !n.isRead);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Row(
                    children: [
                      Material(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: context.colors.border),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: context.colors.primary,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'التنبيهات',
                          style: AppTextStyles.cairoBold18.copyWith(
                            color: context.colors.text,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Material(
                          color: context.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.r),
                            onTap: () =>
                                NotificationRepository.instance.markAllAsRead(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle02,
                                    color: context.colors.primary,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'تحديد الكل كمقروء',
                                    style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.primary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: notifications.isEmpty
                      ? const _EmptyState()
                      : ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                          children: [
                            if (todayItems.isNotEmpty) ...[
                              const _SectionLabel(label: 'اليوم'),
                              SizedBox(height: 8.h),
                              for (int i = 0; i < todayItems.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: _AnimatedItem(
                                    index: i,
                                    total: notifications.length,
                                    controller: _entranceController,
                                    child: NotificationTile(
                                      notification: todayItems[i],
                                      onDeleted: () {},
                                    ),
                                  ),
                                ),
                              SizedBox(height: 8.h),
                            ],
                            if (earlierItems.isNotEmpty) ...[
                              const _SectionLabel(label: 'أقدم'),
                              SizedBox(height: 8.h),
                              for (int i = 0; i < earlierItems.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: _AnimatedItem(
                                    index: todayItems.length + i,
                                    total: notifications.length,
                                    controller: _entranceController,
                                    child: NotificationTile(
                                      notification: earlierItems[i],
                                      onDeleted: () {},
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.cairoMedium16.copyWith(
        color: context.colors.textMuted,
        fontSize: 12.sp,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: context.colors.primary,
              size: 30.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'مفيش تنبيهات دلوقتي',
            style: AppTextStyles.cairoMedium16.copyWith(
              color: context.colors.textMuted,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedItem extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final Widget child;

  const _AnimatedItem({
    required this.index,
    required this.total,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final start = (index / safeTotal) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
