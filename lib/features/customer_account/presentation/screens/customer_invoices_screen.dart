import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_cubit.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_state.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/customer_invoices_view.dart';

class CustomerInvoicesScreen extends StatelessWidget {
  static const int recentMonths = CustomerInvoicesState.recentMonths;

  final String customerId;
  final String customerName;
  final double currentBalance;
  final VoidCallback? onExportPdf;

  const CustomerInvoicesScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.currentBalance = 0,
    this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerInvoicesCubit>(
      create: (_) => CustomerInvoicesCubit(customerId: customerId)..load(),
      child: CustomerInvoicesView(
        customerName: customerName,
        currentBalance: currentBalance,
        onExportPdf: onExportPdf,
      ),
    );
  }
}
