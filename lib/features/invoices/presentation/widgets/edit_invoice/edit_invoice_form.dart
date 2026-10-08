import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_actions.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_item_card.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_items_header.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_pagination.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_totals_card.dart';

class EditInvoiceForm extends StatelessWidget {
  const EditInvoiceForm({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditInvoiceCubit>();

    return BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
      buildWhen: (previous, current) =>
          previous.loading != current.loading ||
          previous.items != current.items ||
          previous.currentPage != current.currentPage,
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            EditInvoiceItemsHeader(
              onAddProduct: () => addInvoiceProduct(context),
            ),
            SizedBox(height: 10.h),
            ...state.pageItems.map(
              (item) => EditInvoiceItemCard(
                item: item,
                onIncrease: () => cubit.increaseQuantity(item),
                onDecrease: () => cubit.decreaseQuantity(item),
                onEditQuantity: (value) => cubit.setQuantity(item, value),
                onEditPrice: () => editInvoiceItemPrice(context, item),
                onRemove: () => cubit.removeItem(item),
              ),
            ),
            if (state.pageCount > 1)
              EditInvoicePagination(
                page: state.currentPage,
                pageCount: state.pageCount,
                onChanged: cubit.changePage,
              ),
            SizedBox(height: 14.h),
            const EditInvoiceTotalsCard(),
            SizedBox(height: 14.h),
            TextField(
              controller: cubit.notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التعديلات',
                alignLabelWithHint: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
