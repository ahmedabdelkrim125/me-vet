import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_items.dart';

class DetachedSettingsButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const DetachedSettingsButton({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = appNavItems.last;
    final color = isSelected ? Colors.white : colors.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.background,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.subtleShadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: isSelected ? colors.primary : colors.surface,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: HugeIcon(icon: item.icon, size: 20.sp, color: color),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          item.label,
          style: AppTextStyles.cairoRegular14.copyWith(
            fontSize: 10.sp,
            color: isSelected ? colors.primary : colors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
