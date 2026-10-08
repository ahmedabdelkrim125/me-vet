import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';

class ProductPickerArgs {
  final List<InvoiceLineItemModel> existing;
  final List<ProductModel> products;
  final Map<String, CustomerProductPrice> customerPrices;
  final Map<String, int> stockByProductId;

  const ProductPickerArgs({
    required this.existing,
    required this.products,
    required this.customerPrices,
    required this.stockByProductId,
  });
}
