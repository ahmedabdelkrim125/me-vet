import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_visits/customers/domain/models/customer_model.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_cubit.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_invoice_view.dart';

class AdminHistoricalInvoiceScreen extends StatelessWidget {
  final CustomerModel customer;

  const AdminHistoricalInvoiceScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoricalInvoiceCubit>(
      create: (_) =>
          HistoricalInvoiceCubit(customerId: customer.id)..loadCatalog(),
      child: HistoricalInvoiceView(customerName: customer.name),
    );
  }
}
