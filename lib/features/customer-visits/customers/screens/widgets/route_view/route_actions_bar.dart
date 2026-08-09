import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteActionsBar extends StatelessWidget {
  final VoidCallback onReportTap;
  final VoidCallback onReloadTap;

  const RouteActionsBar({
    super.key,
    required this.onReportTap,
    required this.onReloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'تقرير الخط',
            filled: true,
            onTap: onReportTap,
            iconBuilder: (color) => HugeIcon(
              icon: HugeIcons.strokeRoundedInvoice01,
              size: 15.sp,
              color: color,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _ActionButton(
            label: 'طلب إعادة تحميل العربية',
            filled: false,
            onTap: onReloadTap,
            iconBuilder: (color) => HugeIcon(
              icon: HugeIcons.strokeRoundedCircleArrowReload01,
              size: 15.sp,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final Widget Function(Color color) iconBuilder;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : context.colors.primary;

    return Material(
      color: filled ? context.colors.primary : context.colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: filled ? Colors.transparent : context.colors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBuilder(color),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: color, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
