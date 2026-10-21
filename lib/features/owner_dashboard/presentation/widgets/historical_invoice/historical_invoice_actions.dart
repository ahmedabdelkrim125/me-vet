import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_cubit.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_state.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_line_dialog.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_product_picker_sheet.dart';

Future<void> pickHistoricalInvoiceDate(BuildContext context) async {
  final cubit = context.read<HistoricalInvoiceCubit>();
  final picked = await showDatePicker(
    context: context,
    initialDate: cubit.state.invoiceDate,
    firstDate: DateTime(2015),
    lastDate: DateTime.now(),
  );
  if (picked != null) cubit.setInvoiceDate(picked);
}

Future<void> addHistoricalProduct(BuildContext context) async {
  final cubit = context.read<HistoricalInvoiceCubit>();
  final product = await showModalBottomSheet<ProductModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HistoricalProductPickerSheet(catalog: cubit.state.catalog),
  );
  if (product == null || !context.mounted) return;

  if (cubit.hasProduct(product)) {
    cubit.incrementExisting(product);
    return;
  }

  final input = await showDialog<HistoricalLineInput>(
    context: context,
    builder: (_) => HistoricalLineDialog(
      productName: product.name,
      quantity: 1,
      unitPrice: product.basePrice,
    ),
  );
  if (input != null) cubit.addLine(product, input.quantity, input.price);
}

Future<void> editHistoricalLine(
  BuildContext context,
  HistoricalInvoiceLine line,
) async {
  final cubit = context.read<HistoricalInvoiceCubit>();
  final input = await showDialog<HistoricalLineInput>(
    context: context,
    builder: (_) => HistoricalLineDialog(
      productName: line.product.name,
      quantity: line.quantity,
      unitPrice: line.unitPrice,
    ),
  );
  if (input != null) cubit.updateLine(line, input.quantity, input.price);
}
