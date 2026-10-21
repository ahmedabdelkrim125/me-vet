import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';

class CustomerEmptyState extends StatelessWidget {
  final VoidCallback onPick;
  const CustomerEmptyState({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InvoiceSectionTitle(
            icon: Icons.storefront_outlined, title: 'بيانات العميل'),
        SizedBox(height: 12.h),
        Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: colors.primary.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.person_search_rounded,
                        color: colors.primary, size: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'اختر العميل للإصدار الفاتورة',
                      style: AppTextStyles.cairoMedium16.copyWith(
                        color: colors.text,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded,
                      color: colors.primary, size: 20.sp),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
