import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_state.dart';
import 'package:mivet_app/features/customer_account/presentation/models/statement_entry.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/invoice_statement_row.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/payment_statement_row.dart';

class StatementGroups extends StatelessWidget {
  final CustomerInvoicesState state;
  final ValueChanged<String> onOpenInvoice;

  const StatementGroups({
    super.key,
    required this.state,
    required this.onOpenInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final groups = state.groups;
    final oldDebtByCode = state.oldDebtByInvoiceCode;
    final sources = state.collectionSources;

    Widget buildEntry(StatementEntry entry) {
      final invoice = entry.invoice;
      if (invoice == null) return PaymentStatementRow(payment: entry.payment!);
      return InvoiceStatementRow(
        invoice: invoice,
        oldDebtCollected: oldDebtByCode[invoice.code] ?? 0,
        hasOldDebtSource: sources.containsKey(invoice.id),
        collectedViaInvoiceCode: sources[invoice.id],
        onTap: () => onOpenInvoice(sources[invoice.id] ?? invoice.code),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
            child: Text(
              group.key,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: colors.border),
            ),
            child: Column(children: group.value.map(buildEntry).toList()),
          ),
        ],
      ],
    );
  }
}
