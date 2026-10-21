import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_insight_badge.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_card.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';

class InvoicePurchaseAnalysisSection extends StatelessWidget {
  final InvoiceCustomerModel customer;
  const InvoicePurchaseAnalysisSection({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InvoiceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InvoiceSectionTitle(
              icon: Icons.insights_rounded, title: 'تحليل المشتريات للعميل'),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.topPurchasedProducts.isNotEmpty)
                Expanded(
                  child: InvoiceInsightBadge(
                    title: 'أكثر المنتجات شراءً',
                    items: customer.topPurchasedProducts,
                    color: colors.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              if (customer.topPurchasedProducts.isNotEmpty &&
                  customer.notPurchasedRecently.isNotEmpty)
                SizedBox(width: 12.w),
              if (customer.notPurchasedRecently.isNotEmpty)
                Expanded(
                  child: InvoiceInsightBadge(
                    title: 'لم يشتريها منذ فترة',
                    items: customer.notPurchasedRecently,
                    color: colors.statOrange,
                    icon: Icons.history_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
