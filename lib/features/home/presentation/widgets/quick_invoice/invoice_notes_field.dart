import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';

class InvoiceNotesField extends StatelessWidget {
  final TextEditingController controller;
  const InvoiceNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InvoiceSectionTitle(
            icon: Icons.edit_note_rounded, title: 'ملاحظات إضافية'),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظاتك على الزيارة أو الفاتورة...',
            hintStyle: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted),
            filled: true,
            fillColor: colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
        ),
      ],
    );
  }
}
