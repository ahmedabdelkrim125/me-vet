import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/invoice_line_input.dart';
import '../domain/models/invoice_record_model.dart';

class InvoiceItemRow {
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const InvoiceItemRow({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}

class InvoiceFullDetail {
  final String code;
  final DateTime date;
  final double subtotal;
  final double discountPercent;
  final double totalAmount;
  final double paidNow;
  final String saleType;
  final String statusLabel;
  final String? notes;
  final List<InvoiceItemRow> items;

  const InvoiceFullDetail({
    required this.code,
    required this.date,
    required this.subtotal,
    required this.discountPercent,
    required this.totalAmount,
    required this.paidNow,
    required this.saleType,
    required this.statusLabel,
    required this.notes,
    required this.items,
  });

  double get remaining => totalAmount - paidNow;
}

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
    var query =
        _supabase.from('invoices').select().eq('customer_id', customerId);

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

  Future<InvoiceFullDetail> getInvoiceDetailByCode(String code) async {
    final invoice =
        await _supabase.from('invoices').select().eq('code', code).single();

    final itemRows = await _supabase
        .from('invoice_items')
        .select('product_name, unit_price, quantity, line_total')
        .eq('invoice_id', invoice['id'] as String);

    final items = (itemRows as List).map((r) {
      final m = r as Map<String, dynamic>;
      return InvoiceItemRow(
        productName: m['product_name'] as String? ?? '',
        unitPrice: (m['unit_price'] as num).toDouble(),
        quantity: (m['quantity'] as num).toInt(),
        lineTotal: (m['line_total'] as num).toDouble(),
      );
    }).toList();

    return InvoiceFullDetail(
      code: invoice['code'] as String,
      date: DateTime.parse(invoice['invoice_date'] as String),
      subtotal: (invoice['subtotal'] as num).toDouble(),
      discountPercent: (invoice['discount_percent'] as num).toDouble(),
      totalAmount: (invoice['total_amount'] as num).toDouble(),
      paidNow: (invoice['paid_now'] as num).toDouble(),
      saleType: invoice['sale_type'] == 'cash' ? 'نقدي' : 'آجل',
      statusLabel: _statusLabelFromDb(invoice['status'] as String?),
      notes: invoice['notes'] as String?,
      items: items,
    );
  }

  String _statusLabelFromDb(String? value) {
    switch (value) {
      case 'paid':
        return 'مدفوعة';
      case 'partial':
        return 'جزئي';
      default:
        return 'آجلة';
    }
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
      final lastDate = DateTime.parse((latest['invoices']
          as Map<String, dynamic>)['invoice_date'] as String);
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
