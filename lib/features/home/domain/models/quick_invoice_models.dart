import 'package:mivet_app/features/customer-visits/customers/domain/models/customer_model.dart';

class InvoiceCustomerModel {
  final CustomerModel customer;

  final List<String> topPurchasedProducts;
  final List<String> notPurchasedRecently;

  const InvoiceCustomerModel({
    required this.customer,
    this.topPurchasedProducts = const [],
    this.notPurchasedRecently = const [],
  });

  /// Remaining credit the customer can still purchase on.
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

/// معلومات الفاتورة بعد إصدارها — بترجع عن طريق onIssued عشان أي
/// حد مستخدم للـ dialog يقدر يحدّث رصيد العميل ويسجل الفاتورة.
class IssuedInvoiceInfo {
  final String invoiceNumber;
  final double amount;
  final String saleType;
  final DateTime date;

  const IssuedInvoiceInfo({
    required this.invoiceNumber,
    required this.amount,
    required this.saleType,
    required this.date,
  });
}
