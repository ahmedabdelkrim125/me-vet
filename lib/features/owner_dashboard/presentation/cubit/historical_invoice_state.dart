import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

class HistoricalInvoiceLine {
  final ProductModel product;
  final int quantity;
  final double unitPrice;

  const HistoricalInvoiceLine({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  HistoricalInvoiceLine copyWith({int? quantity, double? unitPrice}) {
    return HistoricalInvoiceLine(
      product: product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class HistoricalInvoiceState {
  final bool loadingCatalog;
  final List<ProductModel> catalog;
  final DateTime invoiceDate;
  final bool isCashSale;
  final PaymentMethod paymentMethod;
  final List<HistoricalInvoiceLine> lines;
  final bool submitting;
  final double discountAmount;
  final double paidNow;
  final String? info;
  final Object? error;
  final bool submitted;

  const HistoricalInvoiceState({
    required this.invoiceDate,
    this.loadingCatalog = true,
    this.catalog = const [],
    this.isCashSale = false,
    this.paymentMethod = PaymentMethod.cash,
    this.lines = const [],
    this.submitting = false,
    this.discountAmount = 0,
    this.paidNow = 0,
    this.info,
    this.error,
    this.submitted = false,
  });

  double get subtotal => lines.fold<double>(0, (sum, line) => sum + line.total);
  double get total => subtotal - discountAmount;

  HistoricalInvoiceState copyWith({
    bool? loadingCatalog,
    List<ProductModel>? catalog,
    DateTime? invoiceDate,
    bool? isCashSale,
    PaymentMethod? paymentMethod,
    List<HistoricalInvoiceLine>? lines,
    bool? submitting,
    double? discountAmount,
    double? paidNow,
    String? info,
    Object? error,
    bool submitted = false,
  }) {
    return HistoricalInvoiceState(
      loadingCatalog: loadingCatalog ?? this.loadingCatalog,
      catalog: catalog ?? this.catalog,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      isCashSale: isCashSale ?? this.isCashSale,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lines: lines ?? this.lines,
      submitting: submitting ?? this.submitting,
      discountAmount: discountAmount ?? this.discountAmount,
      paidNow: paidNow ?? this.paidNow,
      info: info,
      error: error,
      submitted: submitted,
    );
  }
}
