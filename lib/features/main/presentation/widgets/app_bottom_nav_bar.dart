import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_item_model.dart';
import 'nav_items.dart';

/// ناف بار سفلي مبني بالكامل يدويًا (من غير أي package خارجي) عشان نتحكم
/// بدقة في كل حاجة: أيقونة + اسم جنب بعض (Row) لكل تاب، النص بيصغّر
/// تلقائيًا لو المساحة ضيقة بدل ما يتقطع بـ "..."، وشعار التطبيق في الأول
/// بيفتح المنيو الجانبي (AppSideMenuDrawer).
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.subtleShadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: [
              _LogoButton(
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
              Container(width: 1, height: 30.h, color: colors.border),
              for (int i = 0; i < appNavItems.length; i++)
                Expanded(
                  child: _NavTab(
                    item: appNavItems[i],
                    isSelected: i == selectedIndex,
                    onTap: () => onTabChange(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Image.asset(AppImages.logoSplash, height: 34.h),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final NavItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isSelected ? colors.primary : colors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            // تينت خفيف بدل ملء صريح بلون غامق (اللي كان "مش لذيذ").
            color: isSelected ? colors.primary.withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: item.icon, size: 19.sp, color: color),
              SizedBox(width: 5.w),
              // Flexible + FittedBox: النص يتصغّر لوحده لو المساحة ضيقة
              // بدل ما يتقطع بـ "..." — "الحل الذكي" المطلوب.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: AppTextStyles.cairoRegular14.copyWith(
                      fontSize: 11.sp,
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
