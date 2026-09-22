import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:printing/printing.dart';

import '../../domain/customer_statement.dart';
import '../../domain/customer_statement_pdf_builder.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';

/// Account statement of the customer for the last [months] months, shown as a
/// PDF preview (share / print included).
///
/// Needs a [CustomerAccountCubit] above it in the tree.
class CustomerStatementPdfScreen extends StatelessWidget {
  static const int months = 6;

  const CustomerStatementPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('كشف حساب آخر 6 شهور'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
      ),
      body: BlocBuilder<CustomerAccountCubit, CustomerAccountState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final ledger = state.ledger;
          if (ledger == null) {
            return const _Message(
              text: 'تعذر تحميل بيانات الحساب، جرّب مرة أخرى',
            );
          }

          final statement =
              CustomerStatement.lastMonths(ledger, months: months);

          if (statement.transactions.isEmpty) {
            return const _Message(
              text: 'لا توجد معاملات خلال آخر 6 شهور',
            );
          }

          return PdfPreview(
            build: (_) => CustomerStatementPdfBuilder.build(
              customerName: state.customerName,
              statement: statement,
            ),
            pdfFileName: 'customer_statement_6_months.pdf',
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTextStyles.cairoRegular14
            .copyWith(color: context.colors.textMuted),
      ),
    );
  }
}
