import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_admin_badge.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_info_row.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_item_row.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_note_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_old_debt_section.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_payment_actions.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_totals_card.dart';

class InvoiceDetailBody extends StatelessWidget {
  final InvoiceFullDetail detail;
  final List<PaymentBreakdownLine> oldDebtLines;
  final double applicableCredit;
  final VoidCallback onCollectPayment;
  final VoidCallback onAdjustOverpayment;
  final VoidCallback onApplyCredit;

  const InvoiceDetailBody({
    super.key,
    required this.detail,
    required this.oldDebtLines,
    required this.applicableCredit,
    required this.onCollectPayment,
    required this.onAdjustOverpayment,
    required this.onApplyCredit,
  });

  String get _formattedDate {
    final date = detail.date;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notes = detail.notes;
    final lastEditReason = detail.lastEditReason;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        if (detail.isFromAdmin) ...[
          InvoiceAdminBadge(creatorName: detail.creatorName),
          SizedBox(height: 12.h),
        ],
        InvoiceInfoCard(
          children: [
            InvoiceInfoRow(label: 'التاريخ', value: _formattedDate),
            InvoiceInfoRow(label: 'الحالة', value: detail.statusLabel),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'المنتجات',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: colors.text,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        for (final item in detail.items) InvoiceItemTile(item: item),
        SizedBox(height: 16.h),
        InvoiceTotalsCard(detail: detail),
        InvoicePaymentActions(
          detail: detail,
          applicableCredit: applicableCredit,
          onCollectPayment: onCollectPayment,
          onAdjustOverpayment: onAdjustOverpayment,
          onApplyCredit: onApplyCredit,
        ),
        if (oldDebtLines.isNotEmpty)
          InvoiceOldDebtSection(detail: detail, lines: oldDebtLines),
        if (notes != null && notes.isNotEmpty)
          InvoiceNoteCard(label: 'ملاحظات', value: notes),
        if (lastEditReason != null && lastEditReason.isNotEmpty)
          InvoiceNoteCard(label: 'ملاحظة آخر تعديل', value: lastEditReason),
      ],
    );
  }
}
