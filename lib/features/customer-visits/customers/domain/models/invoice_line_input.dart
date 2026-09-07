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

  Map<String, dynamic> toRpcJson() => {
        if (productId != null) 'product_id': productId,
        'product_name': productName,
        'unit_price': unitPrice,
        'quantity': quantity,
      };
}
