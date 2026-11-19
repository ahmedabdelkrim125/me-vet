import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceDeletionService {
  InvoiceDeletionService._();

  static final InvoiceDeletionService instance = InvoiceDeletionService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<bool> deleteInvoice({
    required String invoiceId,
    required String ownerPassword,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim();
    final result = await _supabase.rpc(
      'delete_invoice',
      params: {
        'p_invoice_id': invoiceId,
        'p_owner_password': ownerPassword,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'p_reason': trimmedReason,
      },
    );
    return result == true;
  }

  Future<String?> getInvoiceRepId(String invoiceId) async {
    final row = await _supabase
        .from('invoices')
        .select('rep_id')
        .eq('id', invoiceId)
        .maybeSingle();
    return row?['rep_id'] as String?;
  }
}
