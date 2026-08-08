import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class UnplannedVisitButton extends StatelessWidget {
  const UnplannedVisitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {},
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.add_circled_solid,
                color: AppColors.primaryGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'إضافة زيارة غير مخططة',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: AppColors.primary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
