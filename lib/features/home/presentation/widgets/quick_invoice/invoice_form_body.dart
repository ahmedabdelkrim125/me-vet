import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/models/vehicle_stock_info.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/customer_empty_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_account_summary_section.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_customer_info.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_financial_summary_row.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_meta_section.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_notes_field.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_payment_section.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_products_section.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_purchase_analysis_section.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_rep_chip.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_card.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/quick_invoice_actions.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';

class InvoiceFormBody extends StatelessWidget {
  const InvoiceFormBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickInvoiceCubit>();
    final repName = context.watch<AuthCubit>().state.user?.name ?? 'غير معروف';

    return BlocBuilder<QuickInvoiceCubit, QuickInvoiceState>(
      builder: (context, state) {
        final customer = state.customer;
        return SingleChildScrollView(
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InvoiceRepChip(name: repName),
              SizedBox(height: 14.h),
              InvoiceSectionCard(
                child: customer == null
                    ? CustomerEmptyState(
                        onPick: () => openInvoiceCustomerPicker(context),
                      )
                    : InvoiceCustomerInfo(
                        invoice: customer,
                        onChange: () => openInvoiceCustomerPicker(context),
                      ),
              ),
              if (customer != null) ...[
                SizedBox(height: 14.h),
                InvoiceSectionCard(
                  child: InvoiceMetaSection(
                    date: state.invoiceDate,
                    onPickDate: () => openInvoiceDatePicker(context),
                    invoiceNumber: state.invoiceNumber,
                  ),
                ),
                SizedBox(height: 14.h),
                InvoiceFinancialSummaryRow(invoice: customer),
                SizedBox(height: 14.h),
                BlocBuilder<VehicleStockCubit, VehicleStockState>(
                  builder: (context, vehicleStockState) {
                    final stockInfo =
                        VehicleStockInfo.fromState(vehicleStockState);
                    return InvoiceSectionCard(
                      child: InvoiceProductsSection(
                        items: state.lineItems,
                        currentPage: state.currentPage,
                        loadingCustomerPrices: state.loadingCustomerPrices,
                        stockKnown: stockInfo.known,
                        stockErrorMessage: stockInfo.errorMessage,
                        onPageChanged: cubit.changePage,
                        onAdd: () => openInvoiceProductPicker(context),
                        onPriceChanged: cubit.changePrice,
                        onQuantityChanged: cubit.changeQuantity,
                        onRemove: cubit.removeLineItem,
                        subtotal: state.subtotal,
                        discountController: cubit.discountController,
                        onDiscountChanged: cubit.changeDiscount,
                        discountAmount: state.discountAmount,
                        grandTotal: state.grandTotal,
                      ),
                    );
                  },
                ),
                if (state.lineItems.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  InvoiceSectionCard(
                    child: InvoiceAccountSummarySection(
                      previousBalance: state.previousBalance,
                      invoiceTotal: state.grandTotal,
                      paidController: cubit.paidNowController,
                      onPaidChanged: cubit.changePaidNow,
                      remaining: state.remainingBalance,
                    ),
                  ),
                  if (state.paidNow > 0) ...[
                    SizedBox(height: 14.h),
                    InvoicePaymentSection(state: state),
                  ],
                ],
                SizedBox(height: 14.h),
                InvoiceSectionCard(
                  child: InvoiceNotesField(controller: cubit.notesController),
                ),
                if (customer.topPurchasedProducts.isNotEmpty ||
                    customer.notPurchasedRecently.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  InvoicePurchaseAnalysisSection(customer: customer),
                ],
              ] else
                SizedBox(height: 4.h),
            ],
          ),
        );
      },
    );
  }
}
