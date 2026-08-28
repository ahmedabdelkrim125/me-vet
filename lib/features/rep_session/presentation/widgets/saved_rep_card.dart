import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/rep_profile_model.dart';
import 'rep_avatar_picker.dart';

class SavedRepCard extends StatelessWidget {
  final RepProfileModel rep;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  const SavedRepCard({
    super.key,
    required this.rep,
    required this.onContinue,
    required this.onDelete,
  });

  String get _lastSeenLabel {
    final diff = DateTime.now().difference(rep.lastLoginAt);
    if (diff.inMinutes < 1) return 'نشط الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onContinue,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              RepAvatarView(avatarIndex: rep.avatarIndex, size: 46),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rep.name,
                      style: AppTextStyles.cairoMedium16.copyWith(
                          color: colors.text, fontSize: 13.5.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _lastSeenLabel,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: colors.textMuted, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10.r),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(CupertinoIcons.trash,
                      size: 18.sp, color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
