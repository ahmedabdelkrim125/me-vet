import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/payment_breakdown.dart';

class PaymentBreakdownRepository {
  PaymentBreakdownRepository._();

  static final PaymentBreakdownRepository instance =
      PaymentBreakdownRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

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

  Future<List<PaymentBreakdownLine>> getForInvoice(String invoiceId) async {
    final rows = await _supabase.rpc(
      'get_invoice_payment_breakdown',
      params: {'p_invoice_id': invoiceId},
    );
    return PaymentBreakdownLine.listFromRows(rows as List<dynamic>);
  }

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
