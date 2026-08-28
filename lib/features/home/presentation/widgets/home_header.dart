import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/arabic_date_utils.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../notification/domain/models/app_notification_model.dart';
import '../../../notification/domain/notification_repository.dart';
import '../../../notification/presentation/screens/notifications_screen.dart';
import '../../../rep_session/data/rep_session_store.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _repName;

  @override
  void initState() {
    super.initState();
    _loadActiveRep();
    NotificationRepository.instance.initialize();
  }

  Future<void> _loadActiveRep() async {
    final rep = await RepSessionStore.instance.getActiveRep();
    if (!mounted) return;
    setState(() => _repName = rep?.name);
  }

  @override
  Widget build(BuildContext context) {
    final greeting =
        _repName == null ? arabicGreeting() : '${arabicGreeting()}، $_repName';

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: Image.asset(
              AppImages.logoSplash,
              height: 100.h,
              width: 100.w,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: AppTextStyles.cairoBold18.copyWith(
                color: context.colors.text,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              arabicDateLabel(),
              style: AppTextStyles.almaraiRegular14.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        _ActionButton(
          icon: HugeIcons.strokeRoundedRefresh,
          onTap: () {},
        ),
        SizedBox(width: 12.w),
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
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: context.colors.primary,
                size: 22.sp,
              ),
              Positioned(
                top: -2.h,
                right: -2.w,
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
                            minWidth: 18.w,
                            minHeight: 18.w,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF16B5E),
                            shape: badgeCount > 9
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: badgeCount > 9
                                ? BorderRadius.circular(10.r)
                                : null,
                            border: Border.all(
                              color: context.colors.surface,
                              width: 1.6,
                            ),
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: AppTextStyles.cairoBold18.copyWith(
                              color: Colors.white,
                              fontSize: 9.sp,
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
    );
  }
}
