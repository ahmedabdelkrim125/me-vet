import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceHeader extends StatelessWidget {
  final String invoiceNumber;
  const InvoiceHeader({super.key, required this.invoiceNumber});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroBackground, colors.secondary],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'MIVET',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: Colors.white, fontSize: 14.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء فاتورة جديدة',
                  style:
                      AppTextStyles.cairoBold18.copyWith(color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 13.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Flexible(
                        child: Text(invoiceNumber,
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }
}
