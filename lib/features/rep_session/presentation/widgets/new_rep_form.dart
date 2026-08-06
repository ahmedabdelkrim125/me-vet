import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'rep_avatar_picker.dart';
import 'rep_primary_button.dart';

class NewRepForm extends StatelessWidget {
  final TextEditingController nameController;
  final int selectedAvatarIndex;
  final ValueChanged<int> onAvatarSelected;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  const NewRepForm({
    super.key,
    required this.nameController,
    required this.selectedAvatarIndex,
    required this.onAvatarSelected,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'مندوب جديد',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: AppColors.primary, fontSize: 14.sp),
            ),
            const Spacer(),
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'رجوع للحسابات المحفوظة',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: AppColors.navInactive, fontSize: 11.5.sp),
                ),
              ),
          ],
        ),
        SizedBox(height: 14.h),
        Center(
          child: RepAvatarPicker(
            selectedIndex: selectedAvatarIndex,
            onSelected: onAvatarSelected,
          ),
        ),
        SizedBox(height: 18.h),
        TextField(
          controller: nameController,
          textAlign: TextAlign.right,
          style: AppTextStyles.cairoMedium16
              .copyWith(color: AppColors.primary, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'اكتب اسمك هنا...',
            hintStyle: AppTextStyles.almaraiRegular14
                .copyWith(color: AppColors.navInactive),
            prefixIcon: Icon(CupertinoIcons.person_alt_circle,
                size: 20.sp, color: AppColors.navInactive),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
          ),
        ),
        SizedBox(height: 18.h),
        RepPrimaryButton(label: 'ابدأ العمل', onTap: onSubmit),
      ],
    );
  }
}
