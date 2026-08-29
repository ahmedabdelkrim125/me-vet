import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/daily_report/domain/models/report_period_type.dart';

class ReportPeriodTabs extends StatelessWidget {
  final List<ReportPeriodType> availablePeriods;
  final ReportPeriodType selected;
  final ValueChanged<ReportPeriodType> onChanged;

  const ReportPeriodTabs({
    super.key,
    required this.availablePeriods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final period in availablePeriods) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == period ? colors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: selected == period ? colors.primary : colors.border,
                  ),
                ),
                child: Text(
                  period.label,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: selected == period ? Colors.white : colors.textMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ),
          if (period != availablePeriods.last) SizedBox(width: 8.w),
        ],
      ],
    );
  }
}
