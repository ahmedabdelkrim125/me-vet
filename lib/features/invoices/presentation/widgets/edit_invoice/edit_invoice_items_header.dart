import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class EditInvoiceItemsHeader extends StatelessWidget {
  final VoidCallback onAddProduct;

  const EditInvoiceItemsHeader({super.key, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Text(
            'أصناف الفاتورة',
            style: AppTextStyles.cairoMedium16.copyWith(
              color: colors.text,
              fontSize: 14.sp,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAddProduct,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(Icons.add, size: 18.sp),
          label: const Text('إضافة منتج'),
        ),
      ],
    );
  }
}
