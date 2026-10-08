import 'package:mivet_app/features/customer_visits/customers/domain/models/customer_model.dart';

class InvoiceCustomerModel {
  final CustomerModel customer;

  final List<String> topPurchasedProducts;
  final List<String> notPurchasedRecently;

  const InvoiceCustomerModel({
    required this.customer,
    this.topPurchasedProducts = const [],
    this.notPurchasedRecently = const [],
  });

  double get availableCredit => (customer.creditLimit - customer.currentBalance)
      .clamp(0, customer.creditLimit);
}

class InvoiceProductModel {
  final String id;
  final String name;
  final double price;
  final String unit;

  const InvoiceProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.unit = 'علبة',
  });
}

class InvoiceLineItemModel {
  final InvoiceProductModel product;
  int quantity;
  double unitPrice;
  final double? previousCustomerPrice;

  InvoiceLineItemModel({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
    this.previousCustomerPrice,
  });

  double get total => unitPrice * quantity;
}

class PastInvoiceSummaryModel {
  final String invoiceNumber;
  final DateTime date;
  final double total;
  final String status;

  const PastInvoiceSummaryModel({
    required this.invoiceNumber,
    required this.date,
    required this.total,
    required this.status,
  });
}

class IssuedInvoiceInfo {
  final String invoiceNumber;
  final double amount;
  final DateTime date;

  const IssuedInvoiceInfo({
    required this.invoiceNumber,
    required this.amount,
    required this.date,
  });
}
