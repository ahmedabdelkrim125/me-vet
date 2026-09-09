import 'package:mivet_app/features/inventory/domain/models/product_category.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/inventory/domain/models/product_unit.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';
import 'package:test/test.dart';

void main() {
  final product = ProductModel(
    id: 'product-1',
    name: 'Vitamin X',
    category: ProductCategory.values.first,
    unit: ProductUnit.values.first,
    retailPrice: 200,
    wholesalePrice: 200,
    minStockThreshold: 1,
    createdAt: DateTime(2024),
  );

  test("uses the customer's previous price when available", () {
    final price = suggestedPrice(product, {
      product.id: const CustomerProductPrice(
        customerId: 'customer-1',
        productId: 'product-1',
        lastPrice: 175,
      ),
    });

    expect(price, 175);
  });

  test('falls back to the product base price', () {
    expect(suggestedPrice(product, {}), 200);
  });

  test('manual price and quantity are represented in the draft item', () {
    final item =
        InvoiceItemDraft(product: product, unitPrice: 180, quantity: 2);

    expect(item.total, 360);
    expect(item.toRpcJson()['unit_price'], 180);
  });

  test('paginates at most 15 items and preserves edited items', () {
    final draft = InvoiceDraft();
    for (var index = 0; index < 31; index++) {
      draft.items.add(InvoiceItemDraft(product: product, unitPrice: 200));
    }
    draft.items[16].unitPrice = 180;

    expect(draft.pageCount, 3);
    expect(draft.itemsForPage(1), hasLength(15));
    expect(draft.itemsForPage(2), hasLength(15));
    expect(draft.itemsForPage(3), hasLength(1));
    expect(draft.itemsForPage(2)[1].unitPrice, 180);
  });

  test('deleting items changes page count without changing remaining data', () {
    final draft = InvoiceDraft();
    for (var index = 0; index < 16; index++) {
      draft.items
          .add(InvoiceItemDraft(product: product, unitPrice: index.toDouble()));
    }

    final removed = draft.items[15];
    draft.remove(removed);

    expect(draft.pageCount, 1);
    expect(draft.items.first.unitPrice, 0);
  });
}
