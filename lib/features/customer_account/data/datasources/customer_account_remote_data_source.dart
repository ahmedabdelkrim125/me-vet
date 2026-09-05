import 'package:supabase_flutter/supabase_flutter.dart';

/// The ONLY class in this feature allowed to talk to Supabase. Calls the
/// three verified RPCs exactly as documented in the backend contract:
/// get_customer_ledger, record_customer_payment, create_sales_return.
class CustomerAccountRemoteDataSource {
  const CustomerAccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<dynamic>> getCustomerLedger({
    required String customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _client.rpc('get_customer_ledger', params: {
      'p_customer_id': customerId,
      'p_from': from?.toIso8601String(),
      'p_to': to?.toIso8601String(),
    });
    return result as List<dynamic>;
  }

  Future<Map<String, dynamic>> recordCustomerPayment({
    required String customerId,
    required double amount,
    String? invoiceId,
    required String source,
    String? notes,
  }) async {
    final result = await _client.rpc('record_customer_payment', params: {
      'p_customer_id': customerId,
      'p_amount': amount,
      'p_invoice_id': invoiceId,
      'p_source': source,
      'p_notes': notes,
    });
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSalesReturn({
    required String customerId,
    required String invoiceId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
  }) async {
    final result = await _client.rpc('create_sales_return', params: {
      'p_customer_id': customerId,
      'p_invoice_id': invoiceId,
      'p_items': items,
      'p_reason': reason,
      'p_notes': notes,
    });
    return result as Map<String, dynamic>;
  }
}