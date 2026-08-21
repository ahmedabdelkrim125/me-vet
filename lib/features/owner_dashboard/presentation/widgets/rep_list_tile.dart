import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/domain/models/user_profile.dart';
import 'package:intl/intl.dart' as intl;

class RepListTile extends StatelessWidget {
  final UserProfile rep;
  final VoidCallback onDelete;

  const RepListTile({
    super.key,
    required this.rep,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final arabicDateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24.w,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            child: Text(
              rep.avatarIndex.toString(),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // معلومات المندوب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rep.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14.w,
                      color: AppColors.navInactive,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      rep.phone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: AppColors.navInactive,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'انضم: ${arabicDateFormat.format(rep.createdAt)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: AppColors.navInactive,
                  ),
                ),
              ],
            ),
          ),
          // زر الحذف
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.statusNotReached,
              size: 22.w,
            ),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }
}
