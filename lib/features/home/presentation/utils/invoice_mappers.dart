import 'package:mivet_app/features/customer_visits/customers/data/customers_repository.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

List<InvoiceCustomerModel> invoiceCustomersFromRepository() {
  return CustomersRepository.instance.customers
      .map((c) => InvoiceCustomerModel(customer: c))
      .toList();
}

InvoiceProductModel invoiceProductFromInventory(ProductModel product) {
  return InvoiceProductModel(
    id: product.id,
    name: product.name,
    price: product.basePrice,
  );
}
