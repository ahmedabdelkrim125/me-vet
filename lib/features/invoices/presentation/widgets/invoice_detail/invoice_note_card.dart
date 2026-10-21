import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';

class InvoiceNoteCard extends StatelessWidget {
  final String label;
  final String value;

  const InvoiceNoteCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: InvoiceInfoCard(
        children: [InvoiceInfoRow(label: label, value: value)],
      ),
    );
  }
}
