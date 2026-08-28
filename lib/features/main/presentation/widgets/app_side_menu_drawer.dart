import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'nav_items.dart';

/// المنيو الجانبي — بيتفتح بالضغط على شعار التطبيق في بداية الناف بار.
/// بيعرض كل الشاشات (appNavItems) كقائمة، وبيقفل نفسه تلقائيًا بعد أي اختيار.
class AppSideMenuDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const AppSideMenuDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      backgroundColor: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Row(
                children: [
                  Image.asset(AppImages.logoSplash, height: 48.h),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            SizedBox(height: 8.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemCount: appNavItems.length,
                itemBuilder: (context, index) {
                  final item = appNavItems[index];
                  final isSelected = index == selectedIndex;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Material(
                      color: isSelected
                          ? colors.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () {
                          Navigator.of(context).pop();
                          onTabChange(index);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 13.h),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: item.icon,
                                size: 22.sp,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textMuted,
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                    fontSize: 14.sp,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.text,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
