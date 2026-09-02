import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/arabic_date_utils.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notification/domain/models/app_notification_model.dart';
import '../../../notification/domain/notification_repository.dart';
import '../../../notification/presentation/screens/notifications_screen.dart';
import '../cubit/home_cubit.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  void initState() {
    super.initState();
    NotificationRepository.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userName = context.watch<AuthCubit>().state.user?.name;
    final greeting =
        userName == null ? arabicGreeting() : '${arabicGreeting()}، $userName';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.subtleShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'القائمة',
            child: Material(
              color: colors.background,
              borderRadius: BorderRadius.circular(18.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(18.r),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 54.w,
                  height: 54.w,
                  alignment: Alignment.center,
                  child: Image.asset(AppImages.logoSplash, height: 38.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: colors.text,
                    fontSize: 17.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  arabicDateLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _ActionButton(
            icon: HugeIcons.strokeRoundedRefresh,
            onTap: () =>
                context.read<HomeCubit>().loadWeeklySummary(forceRefresh: true),
          ),
          SizedBox(width: 8.w),
          ValueListenableBuilder<List<AppNotificationModel>>(
            valueListenable:
                NotificationRepository.instance.notificationsNotifier,
            builder: (context, notifications, _) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return _ActionButton(
                icon: HugeIcons.strokeRoundedNotification01,
                badgeCount: unreadCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: badgeCount > 0 ? 'الإشعارات' : 'تحديث',
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                HugeIcon(
                  icon: icon,
                  color: colors.primary,
                  size: 21.sp,
                ),
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: badgeCount > 0
                        ? Container(
                            key: ValueKey(badgeCount),
                            padding: EdgeInsets.symmetric(
                              horizontal: badgeCount > 9 ? 5.w : 0,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 17.w,
                              minHeight: 17.w,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF16B5E),
                              shape: badgeCount > 9
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: badgeCount > 9
                                  ? BorderRadius.circular(9.r)
                                  : null,
                              border: Border.all(
                                color: colors.surface,
                                width: 1.6,
                              ),
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: AppTextStyles.cairoBold18.copyWith(
                                color: Colors.white,
                                fontSize: 8.5.sp,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-badge')),
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
