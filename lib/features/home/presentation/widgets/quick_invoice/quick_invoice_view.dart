import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_footer_actions.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_form_body.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_header.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/quick_invoice_actions.dart';

class QuickInvoiceView extends StatelessWidget {
  final ValueChanged<IssuedInvoiceInfo>? onIssued;

  const QuickInvoiceView({super.key, this.onIssued});

  void _handleNotice(BuildContext context, QuickInvoiceState state) {
    final message = state.message;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    final error = state.error;
    if (error != null) showAppError(context, error);
    final issued = state.issued;
    if (issued != null) {
      onIssued?.call(issued);
      Navigator.pop(context);
      showAppSuccess(
        context,
        'تم إصدار الفاتورة بنجاح: ${issued.invoiceNumber}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocListener<QuickInvoiceCubit, QuickInvoiceState>(
      listenWhen: (previous, current) =>
          current.message != null ||
          current.error != null ||
          current.issued != null,
      listener: _handleNotice,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocSelector<QuickInvoiceCubit, QuickInvoiceState, String>(
                selector: (state) => state.invoiceNumber,
                builder: (context, invoiceNumber) =>
                    InvoiceHeader(invoiceNumber: invoiceNumber),
              ),
              const Expanded(child: InvoiceFormBody()),
              BlocBuilder<QuickInvoiceCubit, QuickInvoiceState>(
                buildWhen: (previous, current) =>
                    previous.canIssue != current.canIssue ||
                    previous.isIssuing != current.isIssuing,
                builder: (context, state) => InvoiceFooterActions(
                  canIssue: state.canIssue,
                  isIssuing: state.isIssuing,
                  onSave: () => submitInvoice(context),
                  onPrint: () => printInvoice(context),
                  onShareWhatsapp: () => shareInvoiceOnWhatsapp(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
