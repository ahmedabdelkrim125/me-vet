class SalesReturnItemInput {
  final String invoiceItemId;
  final int quantity;

  const SalesReturnItemInput({
    required this.invoiceItemId,
    required this.quantity,
  });

  Map<String, dynamic> toRpcJson() => {
        'invoice_item_id': invoiceItemId,
        'quantity': quantity,
      };
}

class SalesReturn {
  final String? id;
  final String? code;
  final String customerId;
  final String invoiceId;
  final String reason;
  final String? notes;

  const SalesReturn({
    this.id,
    this.code,
    required this.customerId,
    required this.invoiceId,
    required this.reason,
    this.notes,
  });
}
