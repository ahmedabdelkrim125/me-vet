import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import 'dock_surface.dart';
import 'nav_items.dart';

/// Settings entry that sits next to the navigation pill as its own
/// floating button (same height and glass style as the pill).
class DetachedSettingsButton extends StatelessWidget {
  final double height;
  final bool isSelected;
  final VoidCallback onTap;

  const DetachedSettingsButton({
    super.key,
    required this.height,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = appNavItems.last;
    final color = isSelected ? Colors.white : colors.textMuted;

    return DockSurface(
      height: height,
      width: 74.w,
      radius: 28.r,
      fillColor: isSelected ? colors.primary : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: item.icon, size: 22.sp, color: color),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: AppTextStyles.cairoRegular14.copyWith(
                      fontSize: 10.sp,
                      height: 1.2,
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
