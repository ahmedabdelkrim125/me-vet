import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_view.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceCode;
  final String customerName;
  final double previousBalanceAtView;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceDetailCubit>(
      create: (_) => InvoiceDetailCubit(
        invoiceCode: invoiceCode,
        customerName: customerName,
        previousBalanceAtView: previousBalanceAtView,
      )..load(),
      child: const InvoiceDetailView(),
    );
  }
}
