import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_extension.dart';
import '../theme/app_color_scheme_extension.dart';
import '../theme/app_text_styles.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final Color? primaryButtonColor;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.primaryButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      backgroundColor: context.colors.surface,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.cairoMedium16.copyWith(color: context.colors.text),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              content,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: context.colors.text.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPrimaryPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: primaryButtonColor ?? const Color(0xFFA11B1B),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        primaryButtonText,
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: onSecondaryPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        secondaryButtonText,
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: context.colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
