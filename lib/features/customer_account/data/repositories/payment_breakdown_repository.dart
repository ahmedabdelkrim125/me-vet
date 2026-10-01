import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/payment_breakdown.dart';

/// Reads how each payment of a customer was split between the invoice issued
/// with it and older debt. Read-only.
class PaymentBreakdownRepository {
  PaymentBreakdownRepository._();

  static final PaymentBreakdownRepository instance =
      PaymentBreakdownRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Newest payment first.
  Future<List<PaymentBreakdown>> getForCustomer(
    String customerId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _supabase.rpc(
      'get_customer_payment_breakdown',
      params: {
        'p_customer_id': customerId,
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': to?.toUtc().toIso8601String(),
      },
    );
    return PaymentBreakdown.fromRows(rows as List<dynamic>);
  }

  /// Lines of the payment made together with [invoiceId] — its own amount
  /// plus any older debt collected alongside it. Empty when the invoice was
  /// never paid, or was paid with no old debt attached (nothing extra to
  /// show beyond the invoice's own total).
  Future<List<PaymentBreakdownLine>> getForInvoice(String invoiceId) async {
    final rows = await _supabase.rpc(
      'get_invoice_payment_breakdown',
      params: {'p_invoice_id': invoiceId},
    );
    return PaymentBreakdownLine.listFromRows(rows as List<dynamic>);
  }

  /// For every invoice of this customer that was (fully or partly) settled
  /// as old debt collected alongside a *different* invoice's payment, the
  /// code of that other invoice — keyed by the settled invoice's own id.
  /// An invoice not in the map was paid the normal way (at its own issuance,
  /// or through a standalone collection with no invoice of its own).
  Future<Map<String, String?>> getCollectionSourcesForCustomer(
    String customerId,
  ) async {
    final rows = await _supabase.rpc(
      'get_customer_invoice_collection_sources',
      params: {'p_customer_id': customerId},
    );
    return {
      for (final raw in rows as List<dynamic>)
        (raw as Map<String, dynamic>)['invoice_id'] as String:
            raw['collected_via_invoice_code'] as String?,
    };
  }
}
