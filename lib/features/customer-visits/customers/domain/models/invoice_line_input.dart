class InvoiceLineInput {
  final String? productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const InvoiceLineInput({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  Map<String, dynamic> toRpcJson() => {
        'product_id': (productId != null && _uuidPattern.hasMatch(productId!))
            ? productId
            : '',
        'product_name': productName,
        'unit_price': unitPrice,
        'quantity': quantity,
      };
}
