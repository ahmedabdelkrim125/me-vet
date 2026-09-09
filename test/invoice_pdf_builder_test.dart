import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:test/test.dart';

void main() {
  InvoicePdfLineItem item(int index) => InvoicePdfLineItem(
        name: 'Product $index',
        quantity: 1,
        price: 10,
        total: 10,
      );

  test('PDF pagination keeps 15 items per chunk', () {
    for (final count in [15, 16, 30, 31]) {
      final chunks = InvoicePdfBuilder.paginateItems(
        List.generate(count, item),
      );
      expect(chunks.every((chunk) => chunk.length <= 15), isTrue);
      expect(chunks.expand((chunk) => chunk), hasLength(count));
      expect(chunks.expand((chunk) => chunk).map((value) => value.name),
          orderedEquals(List.generate(count, (index) => 'Product $index')));
    }
  });

  test('PDF pagination creates the expected number of pages', () {
    expect(
      InvoicePdfBuilder.paginateItems(List.generate(15, item)),
      hasLength(1),
    );
    expect(
      InvoicePdfBuilder.paginateItems(List.generate(16, item)),
      hasLength(2),
    );
    expect(
      InvoicePdfBuilder.paginateItems(List.generate(30, item)),
      hasLength(2),
    );
    expect(
      InvoicePdfBuilder.paginateItems(List.generate(31, item)),
      hasLength(3),
    );
  });
}
