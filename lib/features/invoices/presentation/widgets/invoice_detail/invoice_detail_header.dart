import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class InvoiceDetailHeader extends StatelessWidget {
  final String code;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const InvoiceDetailHeader({
    super.key,
    required this.code,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              CupertinoIcons.back,
              color: colors.primary,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'تفاصيل الفاتورة $code',
              style: AppTextStyles.cairoBold18.copyWith(
                color: colors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'تعديل الفاتورة',
            icon: Icon(
              Icons.edit_outlined,
              color: colors.primary,
              size: 21.sp,
            ),
          ),
        ],
      ),
    );
  }
}
