import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class OwnerEmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const OwnerEmailInputField({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'البريد الإلكتروني',
          style: AppTextStyles.cairoMedium16
              .copyWith(color: AppColors.primary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          style: AppTextStyles.cairoMedium16
              .copyWith(fontSize: 16.sp, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'admin@example.com',
            hintStyle: AppTextStyles.cairoMedium16
                .copyWith(fontSize: 14.sp, color: AppColors.navInactive),
            prefixIcon: Icon(
              Icons.email_rounded,
              color: AppColors.primaryGreen,
              size: 20.w,
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.statusNotReached),
            ),
            errorText: errorText,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
