import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../domain/models/customer_detail_model.dart';
import '../domain/models/customer_model.dart';
import 'widgets/customer_detail/customer_account_statement_section.dart';
import 'widgets/customer_detail/customer_detail_header.dart';
import 'widgets/customer_detail/customer_financial_info_card.dart';
import 'widgets/customer_detail/customer_notes_section.dart';
import 'widgets/customer_detail/customer_products_section.dart';
import 'widgets/customer_detail/customer_quick_actions_bar.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final detail = CustomerDetailModel.mock(customer);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomerDetailHeader(customer: customer),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                children: [
                  CustomerQuickActionsBar(customer: customer),
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
