import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class EditInvoiceHeader extends StatelessWidget {
  final String invoiceCode;
  final String customerName;
  final VoidCallback onBack;

  const EditInvoiceHeader({
    super.key,
    required this.invoiceCode,
    required this.customerName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 16.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: colors.primary,
              size: 19.sp,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل الفاتورة $invoiceCode',
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: colors.primary,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  customerName,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
