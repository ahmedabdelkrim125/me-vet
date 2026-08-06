import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/arabic_date_utils.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: AppTextStyles.cairoBold18.copyWith(
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              arabicDateLabel(),
              style: AppTextStyles.almaraiRegular14.copyWith(
                color: AppColors.navInactive,
              ),
            ),
          ],
        ),
        const Spacer(),
        const _ActionButton(
          icon: Icons.sync_rounded,
          hasBadge: false,
        ),
        SizedBox(width: 12.w),
        const _ActionButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;

  const _ActionButton({required this.icon, required this.hasBadge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {},
        child: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 22.sp,
              ),
              if (hasBadge)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: AppColors.statOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
