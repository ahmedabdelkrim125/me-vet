// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../customer_account/presentation/screens/customer_account_screen.dart';
// import '../../../home/domain/models/quick_invoice_models.dart';
// import '../../../home/presentation/widgets/quick_invoice_dialog.dart';

// class CustomerDetailScreen extends StatelessWidget {
//   final CustomerModel customer;

//   const CustomerDetailScreen({super.key, required this.customer});

//   InvoiceCustomerModel _toInvoiceCustomer(
//     CustomerDetailModel detail,
//     CustomerAnalysisState analysis,
//   ) {
//     return InvoiceCustomerModel(
//       customer: detail.customer,
//       topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
//       notPurchasedRecently:
//           analysis.notBoughtRecently.map((p) => p.name).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => CustomerAnalysisCubit(customer.id)..load(),
//       child: ValueListenableBuilder<List<CustomerModel>>(
//         valueListenable: CustomersRepository.instance.customersNotifier,
//         builder: (context, _, __) {
//           final currentCustomer =
//               CustomersRepository.instance.getCustomerById(customer.id) ??
//                   customer;
//           final detail = CustomerDetailModel.mock(currentCustomer);

//           return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
//             builder: (context, analysis) {
//               return Scaffold(
//                 body: SafeArea(
//                   child: Column(
//                     children: [
//                       CustomerDetailHeader(customer: currentCustomer),
//                       Expanded(
//                         child: ListView(
//                           padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
//                           children: [
//                             CustomerQuickActionsBar(
//                               customer: currentCustomer,
//                               onInvoiceTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => QuickInvoiceDialog(
//                                           initialCustomer: _toInvoiceCustomer(
//                                               detail, analysis),
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                               // Was: showCustomerCollectPaymentSheet(context, detail: detail).
//                               // The old collection-only sheet is replaced by the full
//                               // customer financial account (invoices, payments, returns,
//                               // running balance). NOTE: the "التحصيل" button label lives
//                               // inside CustomerQuickActionsBar (not provided to us) — its
//                               // text should be updated there to "الحساب والمعاملات" or similar.
//                               onCollectTap: () {
//                                 final cubit =
//                                     context.read<CustomerAnalysisCubit>();
//                                 Navigator.of(context)
//                                     .push(
//                                       MaterialPageRoute(
//                                         builder: (_) => CustomerAccountScreen(
//                                           customerId: currentCustomer.id,
//                                           customerName: currentCustomer.name,
//                                           fallbackBalance:
//                                               currentCustomer.currentBalance,
//                                         ),
//                                       ),
//                                     )
//                                     .then((_) => cubit.load());
//                               },
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerFinancialInfoCard(detail: detail),
//                             SizedBox(height: 16.h),
//                             CustomerTopProductsSection(
//                               products: analysis.topProducts,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotBoughtSection(
//                               products: analysis.notBoughtRecently,
//                               isLoading: analysis.isLoading,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerNotesSection(
//                               customerId: currentCustomer.id,
//                               initialNotes: detail.notes,
//                             ),
//                             SizedBox(height: 16.h),
//                             CustomerVisitHistorySection(
//                                 customerId: currentCustomer.id),
//                             SizedBox(height: 16.h),
//                             CustomerAccountStatementSection(
//                               customerId: currentCustomer.id,
//                               recentInvoices: analysis.recentInvoices,
//                               allInvoices: analysis.allInvoices,
//                               customerName: currentCustomer.name,
//                               currentBalance: currentCustomer.currentBalance,
//                               isLoading: analysis.isLoading,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../customer_account/presentation/screens/customer_account_screen.dart';
import '../../../home/domain/models/quick_invoice_models.dart';
import '../../../home/presentation/widgets/quick_invoice_dialog.dart';
import '../data/customers_repository.dart';
import '../domain/models/customer_detail_model.dart';
import '../domain/models/customer_model.dart';
import '../presentation/cubit/customer_analysis_cubit.dart';
import '../presentation/cubit/customer_analysis_state.dart';
import 'widgets/customer_detail/customer_account_statement_section.dart';
import 'widgets/customer_detail/customer_detail_header.dart';
import 'widgets/customer_detail/customer_financial_info_card.dart';
import 'widgets/customer_detail/customer_notes_section.dart';
import 'widgets/customer_detail/customer_products_section.dart';
import 'widgets/customer_detail/customer_quick_actions_bar.dart';
import 'widgets/customer_detail/customer_visit_history_section.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  InvoiceCustomerModel _toInvoiceCustomer(
    CustomerDetailModel detail,
    CustomerAnalysisState analysis,
  ) {
    return InvoiceCustomerModel(
      customer: detail.customer,
      topPurchasedProducts: analysis.topProducts.map((p) => p.name).toList(),
      notPurchasedRecently:
          analysis.notBoughtRecently.map((p) => p.name).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerAnalysisCubit(customer.id)..load(),
      child: ValueListenableBuilder<List<CustomerModel>>(
        valueListenable: CustomersRepository.instance.customersNotifier,
        builder: (context, _, __) {
          final currentCustomer =
              CustomersRepository.instance.getCustomerById(customer.id) ??
                  customer;
          final detail = CustomerDetailModel.mock(currentCustomer);

          return BlocBuilder<CustomerAnalysisCubit, CustomerAnalysisState>(
            builder: (context, analysis) {
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
                              onInvoiceTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => QuickInvoiceDialog(
                                          initialCustomer: _toInvoiceCustomer(
                                              detail, analysis),
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                              // Was: showCustomerCollectPaymentSheet(context, detail: detail).
                              // The old collection-only sheet is replaced by the full
                              // customer financial account (invoices, payments, returns,
                              // running balance). NOTE: the "التحصيل" button label lives
                              // inside CustomerQuickActionsBar (not provided to us) — its
                              // text should be updated there to "الحساب والمعاملات" or similar.
                              onCollectTap: () {
                                final cubit =
                                    context.read<CustomerAnalysisCubit>();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => CustomerAccountScreen(
                                          customerId: currentCustomer.id,
                                          customerName: currentCustomer.name,
                                          fallbackBalance:
                                              currentCustomer.currentBalance,
                                        ),
                                      ),
                                    )
                                    .then((_) => cubit.load());
                              },
                            ),
                            SizedBox(height: 16.h),
                            CustomerFinancialInfoCard(detail: detail),
                            SizedBox(height: 16.h),
                            CustomerTopProductsSection(
                              products: analysis.topProducts,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotBoughtSection(
                              products: analysis.notBoughtRecently,
                              isLoading: analysis.isLoading,
                            ),
                            SizedBox(height: 16.h),
                            CustomerNotesSection(
                              customerId: currentCustomer.id,
                              initialNotes: detail.notes,
                            ),
                            SizedBox(height: 16.h),
                            CustomerVisitHistorySection(
                                customerId: currentCustomer.id),
                            SizedBox(height: 16.h),
                            CustomerAccountStatementSection(
                              customerId: currentCustomer.id,
                              recentInvoices: analysis.recentInvoices,
                              allInvoices: analysis.allInvoices,
                              customerName: currentCustomer.name,
                              currentBalance: currentCustomer.currentBalance,
                              isLoading: analysis.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}