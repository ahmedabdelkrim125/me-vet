class InvoiceProductSearchResult {
  final String invoiceItemId;
  final String invoiceId;
  final String invoiceCode;
  final DateTime invoiceDate;
  final String customerId;
  final String customerName;
  final String productName;
  final int quantity;
  final double unitPrice;
  final int returnedQuantity;
  final int returnableQuantity;

  const InvoiceProductSearchResult({
    required this.invoiceItemId,
    required this.invoiceId,
    required this.invoiceCode,
    required this.invoiceDate,
    required this.customerId,
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.returnedQuantity,
    required this.returnableQuantity,
  });

  factory InvoiceProductSearchResult.fromJson(Map<String, dynamic> json) {
    return InvoiceProductSearchResult(
      invoiceItemId: json['invoice_item_id'] as String,
      invoiceId: json['invoice_id'] as String,
      invoiceCode: json['invoice_code'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String).toLocal(),
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      returnedQuantity: (json['returned_quantity'] as num?)?.toInt() ?? 0,
      returnableQuantity: (json['returnable_quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
