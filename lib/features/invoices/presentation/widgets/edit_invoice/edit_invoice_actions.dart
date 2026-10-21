import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_product_picker_sheet.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_price_dialog.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_reason_dialog.dart';

Future<void> addInvoiceProduct(BuildContext context) async {
  final cubit = context.read<EditInvoiceCubit>();
  final myId = context.read<AuthCubit>().state.user?.id;
  final stock = await cubit.loadVehicleStockForPicker(myId);
  if (stock == null || !context.mounted) return;
  final product = await showModalBottomSheet<ProductModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditInvoiceProductPickerSheet(
      products: stock.products,
      stockByProductId: stock.quantities,
      existingItems: cubit.state.items,
      customerPrices: cubit.state.customerPrices,
    ),
  );
  if (product == null || !context.mounted) return;
  cubit.addProduct(product);
}

Future<void> editInvoiceItemPrice(
  BuildContext context,
  InvoiceItemDraft item,
) async {
  final cubit = context.read<EditInvoiceCubit>();
  final value = await showDialog<double>(
    context: context,
    builder: (_) => EditPriceDialog(initialPrice: item.unitPrice),
  );
  if (value == null || !context.mounted) return;
  cubit.setPrice(item, value);
}

Future<void> requestSaveInvoice(BuildContext context) async {
  final cubit = context.read<EditInvoiceCubit>();
  if (!cubit.validateForSave()) return;
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const EditReasonDialog(),
  );
  if (reason == null || reason.isEmpty || !context.mounted) return;
  await cubit.save(reason);
}
