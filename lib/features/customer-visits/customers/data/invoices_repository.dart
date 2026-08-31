import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/invoice_line_input.dart';
import '../domain/models/invoice_record_model.dart';

class InvoicesRepository {
  InvoicesRepository._internal();

  static final InvoicesRepository instance = InvoicesRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<InvoiceRecordModel> issueInvoice({
    required String customerId,
    required List<InvoiceLineInput> items,
    required double discountPercent,
    required bool isCashSale,
    required double paidNow,
    String? notes,
  }) async {
    final row = await _supabase.rpc('issue_invoice', params: {
      'p_customer_id': customerId,
      'p_items': items.map((item) => item.toRpcJson()).toList(),
      'p_discount_percent': discountPercent,
      'p_sale_type': isCashSale ? 'cash' : 'credit',
      'p_paid_now': paidNow,
      'p_notes': notes,
    });

    return InvoiceRecordModel.fromSupabaseRow(row as Map<String, dynamic>);
  }

  Future<List<InvoiceRecordModel>> getInvoicesForCustomer(
    String customerId, {
    DateTime? since,
  }) async {
    var query = _supabase
        .from('invoices')
        .select()
        .eq('customer_id', customerId);

    if (since != null) {
      query = query.gte('invoice_date', since.toIso8601String());
    }

    final rows = await query.order('invoice_date', ascending: false);
    return (rows as List)
        .map((row) =>
            InvoiceRecordModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceRecordModel>> getInvoicesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _supabase
        .from('invoices')
        .select()
        .gte('invoice_date', start.toIso8601String())
        .lt('invoice_date', end.toIso8601String())
        .order('invoice_date', ascending: false);
    return (rows as List)
        .map((row) =>
            InvoiceRecordModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }
}
