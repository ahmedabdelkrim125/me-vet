import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';

class EditInvoiceProductPickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  final Map<String, int> stockByProductId;
  final List<InvoiceItemDraft> existingItems;
  final Map<String, CustomerProductPrice> customerPrices;

  const EditInvoiceProductPickerSheet({
    super.key,
    required this.products,
    required this.stockByProductId,
    required this.existingItems,
    required this.customerPrices,
  });

  @override
  State<EditInvoiceProductPickerSheet> createState() =>
      _EditInvoiceProductPickerSheetState();
}

class _EditInvoiceProductPickerSheetState
    extends State<EditInvoiceProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * .82,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن منتج',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  final query = value.text.trim().toLowerCase();
                  final filtered = widget.products.where((product) {
                    return query.isEmpty ||
                        product.name.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد منتجات متاحة في مخزن عربيتك',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final product = filtered[index];
                      final added = widget.existingItems.any(
                        (item) => item.productId == product.id,
                      );
                      final remembered =
                          widget.customerPrices[product.id]?.lastPrice;
                      final priceLabel = remembered == null
                          ? 'لا يوجد سعر سابق لهذا العميل'
                          : 'آخر سعر سابق: ${remembered.toStringAsFixed(2)} ج.م';

                      return ListTile(
                        onTap: () => Navigator.pop(context, product),
                        title: Text(product.name),
                        subtitle: Text(
                          '$priceLabel\nالمتاح في العربية: ${widget.stockByProductId[product.id] ?? 0}',
                        ),
                        trailing: Icon(
                          added
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          color: colors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
