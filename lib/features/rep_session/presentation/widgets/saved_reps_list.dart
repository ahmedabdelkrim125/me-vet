import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/rep_profile_model.dart';
import 'saved_rep_card.dart';

class SavedRepsList extends StatelessWidget {
  final List<RepProfileModel> reps;
  final ValueChanged<RepProfileModel> onContinue;
  final ValueChanged<RepProfileModel> onDelete;
  final VoidCallback onAddNew;

  const SavedRepsList({
    super.key,
    required this.reps,
    required this.onContinue,
    required this.onDelete,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'مين اللي هيشتغل دلوقتي؟',
          style: AppTextStyles.cairoMedium16
              .copyWith(color: AppColors.primary, fontSize: 14.sp),
        ),
        SizedBox(height: 12.h),
        ...reps.map(
          (rep) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: SavedRepCard(
              rep: rep,
              onContinue: () => onContinue(rep),
              onDelete: () => onDelete(rep),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Material(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onAddNew,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border:
                    Border.all(color: AppColors.primaryGreen.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.person_badge_plus_fill,
                      size: 18.sp, color: AppColors.primaryGreen),
                  SizedBox(width: 8.w),
                  Text(
                    'إضافة مندوب جديد',
                    style: AppTextStyles.cairoMedium16.copyWith(
                        color: AppColors.primaryGreen, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
