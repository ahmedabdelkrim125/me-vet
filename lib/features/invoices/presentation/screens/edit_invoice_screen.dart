import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_view.dart';

class EditInvoiceScreen extends StatelessWidget {
  final InvoiceFullDetail invoice;
  final String customerName;
  final String customerId;

  const EditInvoiceScreen({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditInvoiceCubit>(
      create: (_) => EditInvoiceCubit(
        invoice: invoice,
        customerId: customerId,
      )..load(),
      child: EditInvoiceView(customerName: customerName),
    );
  }
}
