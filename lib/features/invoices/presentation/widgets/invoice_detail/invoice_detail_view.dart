import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_actions.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_content.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_footer_actions.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_header.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({super.key});

  void _handleNotice(BuildContext context, InvoiceDetailState state) {
    final message = state.successMessage;
    if (message != null) showAppSuccess(context, message);
    final error = state.error;
    if (error != null) showAppError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final invoiceCode = context.read<InvoiceDetailCubit>().invoiceCode;

    return BlocListener<InvoiceDetailCubit, InvoiceDetailState>(
      listenWhen: (previous, current) =>
          current.successMessage != null || current.error != null,
      listener: _handleNotice,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              BlocSelector<InvoiceDetailCubit, InvoiceDetailState, bool>(
                selector: (state) => state.hasDetail,
                builder: (context, hasDetail) => InvoiceDetailHeader(
                  code: invoiceCode,
                  onBack: () => Navigator.of(context).pop(),
                  onEdit: hasDetail ? () => openEditInvoice(context) : null,
                ),
              ),
              const Expanded(child: InvoiceDetailContent()),
              BlocBuilder<InvoiceDetailCubit, InvoiceDetailState>(
                buildWhen: (previous, current) =>
                    previous.isLoading != current.isLoading ||
                    previous.hasDetail != current.hasDetail,
                builder: (context, state) {
                  if (state.isLoading || !state.hasDetail) {
                    return const SizedBox.shrink();
                  }
                  return InvoiceDetailFooterActions(
                    onPrint: () => printInvoicePdf(context),
                    onShare: () => shareInvoicePdf(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
