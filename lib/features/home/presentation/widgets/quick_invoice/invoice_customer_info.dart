import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';

class InvoiceCustomerInfo extends StatelessWidget {
  final InvoiceCustomerModel invoice;
  final VoidCallback onChange;

  const InvoiceCustomerInfo({
    super.key,
    required this.invoice,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                invoice.customer.name,
                style: AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 15.sp),
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(
                'تغيير',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: colors.primary,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14.sp, color: colors.textMuted),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                invoice.customer.address,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.call_outlined, size: 14.sp, color: colors.textMuted),
            SizedBox(width: 4.w),
            Flexible(
                child: Text(invoice.customer.phone,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}
