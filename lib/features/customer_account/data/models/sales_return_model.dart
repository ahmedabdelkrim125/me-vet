import '../../domain/entities/sales_return.dart';

/// `public.sales_returns`'s full column set is not part of the verified
/// contract (only `id` and `code` are confirmed, via the join used inside
/// `get_customer_ledger`). Parsing here stays deliberately defensive and
/// only reads those two confirmed fields — everything else on this object
/// comes from what Flutter already sent in the request.
class SalesReturnModel extends SalesReturn {
  const SalesReturnModel({
    super.id,
    super.code,
    required super.customerId,
    required super.invoiceId,
    required super.reason,
    super.notes,
  });

  factory SalesReturnModel.fromSupabaseRow(
    Map<String, dynamic> row, {
    required String customerId,
    required String invoiceId,
    required String reason,
    String? notes,
  }) {
    return SalesReturnModel(
      id: row['id'] as String?,
      code: row['code'] as String?,
      customerId: customerId,
      invoiceId: invoiceId,
      reason: reason,
      notes: notes,
    );
  }
}