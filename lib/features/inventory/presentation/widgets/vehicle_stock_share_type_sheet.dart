import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class VehicleStockShareTypeSheet extends StatelessWidget {
  const VehicleStockShareTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: 32.h,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'مشاركة مخزون العربية',
            style: AppTextStyles.cairoBold18.copyWith(color: context.colors.text),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          _buildOptionTile(
            context: context,
            title: 'المنتجات المضافة اليوم',
            subtitle: 'المنتجات التي تمت إضافتها للعربية اليوم',
            icon: CupertinoIcons.calendar_today,
            onTap: () => Navigator.pop(context, 'today'),
          ),
          SizedBox(height: 12.h),
          _buildOptionTile(
            context: context,
            title: 'كل مخزون العربية',
            subtitle: 'كل المنتجات الموجودة حاليًا في العربية',
            icon: CupertinoIcons.cube_box,
            onTap: () => Navigator.pop(context, 'all'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: context.colors.primary, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cairoBold18.copyWith(color: context.colors.text,fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_left, color: context.colors.textMuted, size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }
}