import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_form.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_header.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_save_bar.dart';

class EditInvoiceView extends StatelessWidget {
  final String customerName;

  const EditInvoiceView({super.key, required this.customerName});

  void _handleNotice(BuildContext context, EditInvoiceState state) {
    final error = state.error;
    if (error != null) showAppError(context, error);
    if (state.saved) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final invoiceCode = context.read<EditInvoiceCubit>().invoice.code;

    return BlocListener<EditInvoiceCubit, EditInvoiceState>(
      listenWhen: (previous, current) => current.error != null || current.saved,
      listener: _handleNotice,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              EditInvoiceHeader(
                invoiceCode: invoiceCode,
                customerName: customerName,
                onBack: () => Navigator.pop(context),
              ),
              const Expanded(child: EditInvoiceForm()),
              const EditInvoiceSaveBar(),
            ],
          ),
        ),
      ),
    );
  }
}
