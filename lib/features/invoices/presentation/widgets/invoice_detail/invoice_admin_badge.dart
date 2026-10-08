import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceAdminBadge extends StatelessWidget {
  final String? creatorName;

  const InvoiceAdminBadge({super.key, required this.creatorName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = creatorName;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: colors.primary, size: 15.sp),
          SizedBox(width: 6.w),
          Text(
            name == null || name.isEmpty
                ? 'فاتورة من الإدارة'
                : 'فاتورة من الإدارة — $name',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.primary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
