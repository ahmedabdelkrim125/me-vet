import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/domain/models/user_profile.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';

class SideNavUserCard extends StatelessWidget {
  const SideNavUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<AuthCubit>().state.user;

    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_left_rounded,
              color: colors.textMuted, size: 18.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user?.name ?? '...',
                  style: AppTextStyles.cairoMedium16.copyWith(
                    fontSize: 13.sp,
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  user?.role == UserRole.owner ? 'مدير النظام' : 'مندوب مبيعات',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    fontSize: 11.sp,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 18.w,
            backgroundColor: colors.primary.withOpacity(0.12),
            child:
                Icon(Icons.person_rounded, color: colors.primary, size: 20.sp),
          ),
        ],
      ),
    );
  }
}
