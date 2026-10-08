import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CustomerFieldLabel extends StatelessWidget {
  final String label;

  const CustomerFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.cairoMedium16
          .copyWith(color: context.colors.primary, fontSize: 12.sp),
    );
  }
}

class CustomerTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomerTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        style:
            AppTextStyles.cairoRegular14.copyWith(color: context.colors.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.colors.surface,
          hintText: hint,
          hintStyle: AppTextStyles.almaraiRegular14
              .copyWith(color: context.colors.textMuted, fontSize: 12.sp),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class CustomerLocationButton extends StatelessWidget {
  final bool isLoading;
  final bool hasLocation;
  final VoidCallback? onTap;

  const CustomerLocationButton({
    super.key,
    required this.isLoading,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = hasLocation ? colors.primary : colors.statusNotReached;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 15.w,
                height: 15.w,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Icon(
                hasLocation
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.location_fill,
                size: 16.sp,
                color: accent,
              ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                isLoading
                    ? 'بيتم تحديد موقعك...'
                    : hasLocation
                        ? 'تم تحديد الموقع بدقة — اضغط لإعادة التحديد'
                        : 'أنا هنا دلوقتي — حدد موقعي بدقة',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: accent, fontSize: 11.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomerCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withOpacity(0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(CupertinoIcons.check_mark,
                  size: 13.sp, color: context.colors.primary),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.textMuted,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> customerCategories = [
  'صيدلية بيطرية',
  'عيادة بيطرية',
  'دكتور بيطري',
  'مزرعة دواجن',
  'مزرعة لارج',
];
