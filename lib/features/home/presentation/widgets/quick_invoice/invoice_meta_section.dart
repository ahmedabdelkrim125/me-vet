import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_static_field.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_tappable_field.dart';

class InvoiceMetaSection extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPickDate;
  final String invoiceNumber;

  const InvoiceMetaSection({
    super.key,
        required this.date,
    required this.onPickDate,
    required this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InvoiceSectionTitle(
            icon: Icons.receipt_long_outlined, title: 'بيانات الفاتورة'),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: InvoiceTappableField(
                label: 'التاريخ',
                value: formatDate(date),
                icon: Icons.calendar_today_outlined,
                onTap: onPickDate,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: InvoiceStaticField(
                label: 'رقم الفاتورة',
                value: invoiceNumber,
                icon: Icons.tag_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
