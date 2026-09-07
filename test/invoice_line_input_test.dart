import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_line_input.dart';
import 'package:test/test.dart';

void main() {
  test('preserves the real product id in the invoice payload', () {
    const input = InvoiceLineInput(
      productId: '2d931510-8f9c-4b91-8cb8-3c7b3a1e7a10',
      productName: 'Vitamin X',
      unitPrice: 150,
      quantity: 2,
    );

    expect(input.toRpcJson()['product_id'], input.productId);
  });

  test('omits product id only for an explicitly id-less legacy line', () {
    const input = InvoiceLineInput(
      productId: null,
      productName: 'Legacy item',
      unitPrice: 10,
      quantity: 1,
    );

    expect(input.toRpcJson().containsKey('product_id'), isFalse);
  });
}
