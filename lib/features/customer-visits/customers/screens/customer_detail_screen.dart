import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../home/domain/models/quick_invoice_models.dart';
import '../../../home/presentation/widgets/quick_invoice_dialog.dart';
import '../domain/mock_customers_repository.dart';
import '../domain/models/customer_detail_model.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/invoice_record_model.dart';
import 'widgets/customer_detail/customer_account_statement_section.dart';
import 'widgets/customer_detail/customer_collect_payment_sheet.dart';
import 'widgets/customer_detail/customer_detail_header.dart';
import 'widgets/customer_detail/customer_financial_info_card.dart';
import 'widgets/customer_detail/customer_notes_section.dart';
import 'widgets/customer_detail/customer_products_section.dart';
import 'widgets/customer_detail/customer_quick_actions_bar.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  InvoiceCustomerModel _toInvoiceCustomer(CustomerDetailModel detail) {
    final c = detail.customer;
    return InvoiceCustomerModel(
      customer: c,
      topPurchasedProducts: detail.topProducts.map((p) => p.name).toList(),
      notPurchasedRecently:
          detail.notBoughtRecently.map((p) => p.name).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCustomer =
        MockCustomersRepository.instance.getCustomerById(customer.id) ??
            customer;
    final detail = CustomerDetailModel.mock(currentCustomer);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomerDetailHeader(customer: currentCustomer),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                children: [
                  CustomerQuickActionsBar(
                    customer: currentCustomer,
                    onInvoiceTap: () => showDialog(
                      context: context,
                      builder: (_) => QuickInvoiceDialog(
                          initialCustomer: _toInvoiceCustomer(detail),
                          onIssued: (info) async {
                            final repo = MockCustomersRepository.instance;
                            await repo.adjustBalance(
                                currentCustomer.id, info.amount);
                            await repo.addInvoice(
                              currentCustomer.id,
                              InvoiceRecordModel(
                                code: info.invoiceNumber,
                                date: info.date,
                                amount: info.amount,
                                status: info.saleType == 'نقدي'
                                    ? InvoiceStatus.paid
                                    : InvoiceStatus.deferred,
                              ),
                            );
                          }),
                    ),
                    onCollectTap: () => showCustomerCollectPaymentSheet(
                      context,
                      detail: detail,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomerFinancialInfoCard(detail: detail),
                  SizedBox(height: 16.h),
                  CustomerTopProductsSection(products: detail.topProducts),
                  SizedBox(height: 16.h),
                  CustomerNotBoughtSection(products: detail.notBoughtRecently),
                  SizedBox(height: 16.h),
                  CustomerSeasonalSuggestionsSection(
                      suggestions: detail.seasonalSuggestions),
                  SizedBox(height: 16.h),
                  CustomerNotesSection(initialNotes: detail.notes),
                  SizedBox(height: 16.h),
                  CustomerAccountStatementSection(invoices: detail.invoices),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
