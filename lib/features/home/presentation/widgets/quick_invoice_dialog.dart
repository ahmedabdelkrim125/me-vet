import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_cubit.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/quick_invoice_view.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';

class QuickInvoiceDialog extends StatelessWidget {
  final InvoiceCustomerModel? initialCustomer;
  final ValueChanged<IssuedInvoiceInfo>? onIssued;

  const QuickInvoiceDialog({super.key, this.initialCustomer, this.onIssued});

  @override
  Widget build(BuildContext context) {
    final vehicleStockCubit = sl<VehicleStockCubit>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<VehicleStockCubit>.value(value: vehicleStockCubit),
        BlocProvider<QuickInvoiceCubit>(
          create: (_) => QuickInvoiceCubit(
            vehicleStockCubit: vehicleStockCubit,
            initialCustomer: initialCustomer,
          )..initialize(),
        ),
      ],
      child: QuickInvoiceView(onIssued: onIssued),
    );
  }
}
