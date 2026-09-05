import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:printing/printing.dart';

import '../../domain/customer_statement_pdf_builder.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';

/// Renders the full ledger already loaded by [CustomerAccountCubit] as a
/// PDF. A different document from the per-invoice PDF built by
/// InvoicePdfBuilder — this one covers every transaction type.
class CustomerStatementPdfScreen extends StatelessWidget {
  const CustomerStatementPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('كشف حساب PDF'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
      ),
      body: BlocBuilder<CustomerAccountCubit, CustomerAccountState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ledger = state.ledger;
          if (ledger == null || ledger.transactions.isEmpty) {
            return Center(
              child: Text('لا توجد معاملات لعرضها في كشف الحساب',
                  style: AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted)),
            );
          }
          return PdfPreview(
            build: (_) => CustomerStatementPdfBuilder.build(
              customerName: state.customerName,
              ledger: ledger,
            ),
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
          );
        },
      ),
    );
  }
}