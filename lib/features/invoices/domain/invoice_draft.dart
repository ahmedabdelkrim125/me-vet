import '../../inventory/domain/models/product_model.dart';

class CustomerProductPrice {
  final String customerId;
  final String productId;
  final double lastPrice;

  const CustomerProductPrice({
    required this.customerId,
    required this.productId,
    required this.lastPrice,
  });

  factory CustomerProductPrice.fromJson(Map<String, dynamic> json) {
    return CustomerProductPrice(
      customerId: json['customer_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      lastPrice: (json['last_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InvoiceItemDraft {
  final String? invoiceItemId;
  final ProductModel product;
  int quantity;
  double unitPrice;
  final double? previousCustomerPrice;

  InvoiceItemDraft({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
    this.invoiceItemId,
    this.previousCustomerPrice,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toRpcJson() => {
        if (invoiceItemId != null) 'invoice_item_id': invoiceItemId,
        'product_id': product.id,
        'product_name': product.name,
        'unit_price': unitPrice,
        'quantity': quantity,
      };
}

class InvoiceDraft {
  static const itemsPerPage = 15;

  final List<InvoiceItemDraft> items = [];

  int get pageCount => items.isEmpty ? 1 : (items.length / itemsPerPage).ceil();

  List<InvoiceItemDraft> itemsForPage(int page) {
    final start = (page - 1) * itemsPerPage;
    if (start >= items.length) return const [];
    final end = (start + itemsPerPage).clamp(0, items.length);
    return items.sublist(start, end);
  }

  void remove(InvoiceItemDraft item) => items.remove(item);
}

double suggestedPrice(
  ProductModel product,
  Map<String, CustomerProductPrice> prices,
) {
  return prices[product.id]?.lastPrice ?? product.basePrice;
}
