import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteSummaryCard extends StatelessWidget {
  final int total;
  final int completed;

  const RouteSummaryCard({
    super.key,
    required this.total,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final remaining = total - completed;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed من $total زيارة مكتملة',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: Colors.white, fontSize: 13.sp),
                ),
              ),
              Text(
                '$remaining متبقي',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8.h,
                  backgroundColor: context.colors.surface.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(context.colors.text),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
