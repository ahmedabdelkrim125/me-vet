import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;

  const PinInputField({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رمز PIN',
          style: AppTextStyles.cairoMedium16
              .copyWith(color: AppColors.primary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          obscureText: _obscureText,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: AppTextStyles.cairoMedium16
              .copyWith(fontSize: 16.sp, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: AppTextStyles.cairoMedium16
                .copyWith(color: AppColors.navInactive),
            prefixIcon: Icon(
              Icons.lock_rounded,
              color: AppColors.primaryGreen,
              size: 20.w,
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureText = !_obscureText),
              icon: Icon(
                _obscureText
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.navInactive,
                size: 20.w,
              ),
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
            errorText: widget.errorText,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
