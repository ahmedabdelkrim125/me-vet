class InvoiceCustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  /// Set by management — never editable by the sales rep on this screen.
  final double creditLimit;
  final double currentBalance;
  final DateTime lastPaymentDate;

  final List<String> topPurchasedProducts;
  final List<String> notPurchasedRecently;

  const InvoiceCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.creditLimit,
    required this.currentBalance,
    required this.lastPaymentDate,
    this.topPurchasedProducts = const [],
    this.notPurchasedRecently = const [],
  });

  /// Remaining credit the customer can still purchase on.
  double get availableCredit =>
      (creditLimit - currentBalance).clamp(0, creditLimit);
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

  InvoiceLineItemModel({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// A single row inside the "كشف حساب - آخر 6 شهور" statement sheet.
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
