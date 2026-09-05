/// One line of a sales return request, matching `create_sales_return`'s
/// `p_items` shape: `[{"invoice_item_id":"<uuid>","quantity":1}]`.
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

/// Result of `create_sales_return`. Only `id` and `code` are read from the
/// RPC response — `public.sales_returns`'s other columns are not part of the
/// verified contract, and the ledger refresh (not this object) is what the
/// UI relies on afterwards.
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