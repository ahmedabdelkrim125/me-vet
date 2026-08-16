import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteProgressCard extends StatelessWidget {
  final String routeName;
  final String dayLabel;
  final int totalVisits;
  final int completedVisits;
  final String buttonText;
  final VoidCallback? onButtonTap;

  const RouteProgressCard({
    super.key,
    required this.routeName,
    required this.dayLabel,
    required this.totalVisits,
    required this.completedVisits,
    required this.buttonText,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalVisits - completedVisits;
    final progress = totalVisits == 0 ? 0.0 : completedVisits / totalVisits;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: AppTextStyles.cairoBold18.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      dayLabel,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              _CompletionRing(
                completed: completedVisits,
                total: totalVisits,
                progress: progress,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RouteStat(
                      value: '$remaining',
                      label: 'متبقي',
                      color: AppColors.statOrange,
                    ),
                    const _StatDivider(),
                    _RouteStat(
                      value: '$completedVisits',
                      label: 'تمت',
                      color: AppColors.primaryGreen,
                    ),
                    const _StatDivider(),
                    _RouteStat(
                      value: '$totalVisits',
                      label: 'عميل',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _StartButton(
            buttonText: buttonText,
            expand: true,
            onTap: onButtonTap,
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _CompletionRing({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92.w,
      height: 92.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92.w,
            height: 92.w,
            child: CircularProgressIndicator(
              value: progress == 0 ? 1 : progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(
                progress == 0
                    ? Colors.white.withOpacity(0.15)
                    : AppColors.primaryGreen,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completed / $total',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'زيارة مكتملة',
                textAlign: TextAlign.center,
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32.h,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _RouteStat({
    required this.value,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.cairoBold18.copyWith(color: color)),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final String buttonText;
  final bool expand;
  final VoidCallback? onTap;

  const _StartButton({
    required this.buttonText,
    this.expand = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            spacing: 6.w,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
              ),
              Icon(Icons.add, color: Colors.white, size: 18.sp),
            ],
          ),
        ),
      ),
    );

    if (expand) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
