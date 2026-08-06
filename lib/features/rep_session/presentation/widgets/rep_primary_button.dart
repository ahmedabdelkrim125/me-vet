import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RepPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  const RepPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = CupertinoIcons.arrow_right_circle_fill,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.35),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          elevation: enabled ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: Colors.white, fontSize: 15.sp),
            ),
            SizedBox(width: 8.w),
            Icon(icon, color: Colors.white, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
