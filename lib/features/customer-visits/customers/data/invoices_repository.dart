import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/invoice_line_input.dart';
import '../domain/models/invoice_record_model.dart';

class ProductPurchaseStat {
  final String productName;
  final double lastPrice;
  final DateTime lastPurchaseDate;
  final int timesPurchased;

  const ProductPurchaseStat({
    required this.productName,
    required this.lastPrice,
    required this.lastPurchaseDate,
    required this.timesPurchased,
  });
}

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

  Future<List<ProductPurchaseStat>> getProductStatsForCustomer(
    String customerId,
  ) async {
    final rows = await _supabase
        .from('invoice_items')
        .select('product_name, unit_price, quantity, '
            'invoices!inner(customer_id, invoice_date)')
        .eq('invoices.customer_id', customerId);

    final byProduct = <String, List<Map<String, dynamic>>>{};
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final name = map['product_name'] as String? ?? '';
      if (name.isEmpty) continue;
      byProduct.putIfAbsent(name, () => []).add(map);
    }

    final stats = <ProductPurchaseStat>[];
    byProduct.forEach((name, items) {
      items.sort((a, b) {
        final da = DateTime.parse(
            (a['invoices'] as Map<String, dynamic>)['invoice_date'] as String);
        final db = DateTime.parse(
            (b['invoices'] as Map<String, dynamic>)['invoice_date'] as String);
        return db.compareTo(da);
      });
      final latest = items.first;
      final lastDate = DateTime.parse(
          (latest['invoices'] as Map<String, dynamic>)['invoice_date']
              as String);
      stats.add(ProductPurchaseStat(
        productName: name,
        lastPrice: (latest['unit_price'] as num).toDouble(),
        lastPurchaseDate: lastDate,
        timesPurchased: items.length,
      ));
    });

    return stats;
  }
}
