import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/models/product_picker_args.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_mappers.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';

class ProductPickerState {
  final List<InvoiceLineItemModel> cart;
  final List<InvoiceProductModel> allProducts;
  final List<InvoiceProductModel> visibleProducts;
  final Map<String, String> searchKeys;
  final Map<String, CustomerProductPrice> customerPrices;
  final Map<String, int> stockByProductId;
  final String query;
  final String? message;

  const ProductPickerState({
    required this.cart,
    required this.allProducts,
    required this.visibleProducts,
    required this.searchKeys,
    required this.customerPrices,
    required this.stockByProductId,
    this.query = '',
    this.message,
  });

  factory ProductPickerState.fromArgs(ProductPickerArgs args) {
    final cart = args.existing
        .map((e) => InvoiceLineItemModel(
              product: e.product,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
              previousCustomerPrice: e.previousCustomerPrice,
            ))
        .toList();

    final products = args.products.map(invoiceProductFromInventory).toList();
    final knownIds = products.map((p) => p.id).toSet();
    for (final line in args.existing) {
      if (!knownIds.contains(line.product.id)) products.add(line.product);
    }
    products.sort((a, b) {
      final aBought = args.customerPrices.containsKey(a.id);
      final bBought = args.customerPrices.containsKey(b.id);
      if (aBought != bBought) return aBought ? -1 : 1;
      return a.name.compareTo(b.name);
    });

    return ProductPickerState(
      cart: cart,
      allProducts: products,
      visibleProducts: products,
      searchKeys: {for (final p in products) p.id: normalizeArabic(p.name)},
      customerPrices: args.customerPrices,
      stockByProductId: args.stockByProductId,
    );
  }

  double get cartTotal => cart.fold<double>(0, (sum, line) => sum + line.total);

  int quantityFor(InvoiceProductModel product) {
    final match = cart.where((c) => c.product.id == product.id);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  int availableStockFor(InvoiceProductModel product) =>
      stockByProductId[product.id] ?? 0;

  double? previousPriceFor(InvoiceProductModel product) =>
      customerPrices[product.id]?.lastPrice;

  ProductPickerState copyWith({
    List<InvoiceLineItemModel>? cart,
    List<InvoiceProductModel>? visibleProducts,
    String? query,
    String? message,
  }) {
    return ProductPickerState(
      cart: cart ?? this.cart,
      allProducts: allProducts,
      visibleProducts: visibleProducts ?? this.visibleProducts,
      searchKeys: searchKeys,
      customerPrices: customerPrices,
      stockByProductId: stockByProductId,
      query: query ?? this.query,
      message: message,
    );
  }
}
