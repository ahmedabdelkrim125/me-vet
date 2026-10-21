import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class AddCustomerButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddCustomerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.primary,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 6,
      shadowColor: context.colors.primary.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.add, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'إضافة عميل جديد',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: Colors.white, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
