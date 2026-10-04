import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../customer_account/domain/entities/invoice_product_search_result.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../domain/models/invoice_line_input.dart';
import '../domain/models/invoice_record_model.dart';
import '../../../invoices/domain/invoice_draft.dart';

class InvoiceItemRow {
  final String id;
  final String? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const InvoiceItemRow({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}

class InvoiceFullDetail {
  final String id;
  final String code;
  final String customerId;
  final DateTime date;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double totalAmount;
  final double paidNow;
  final String statusLabel;
  final String? notes;
  final List<InvoiceItemRow> items;
  final String? creatorType;
  final String? creatorName;
  final String? lastEditReason;

  const InvoiceFullDetail({
    required this.id,
    required this.code,
    required this.customerId,
    required this.date,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidNow,
    required this.statusLabel,
    required this.notes,
    required this.items,
    this.creatorType,
    this.creatorName,
    this.lastEditReason,
  });

  double get remaining => totalAmount - paidNow;

  bool get isFromAdmin => creatorType == 'admin';
}

class ProductPurchaseStat {
  final String productId;
  final String productName;
  final double lastPrice;
  final DateTime lastPurchaseDate;
  final int timesPurchased;
  final bool isDeleted;

  const ProductPurchaseStat({
    required this.productId,
    required this.productName,
    required this.lastPrice,
    required this.lastPurchaseDate,
    required this.timesPurchased,
    this.isDeleted = false,
  });
}

class InvoicesRepository {
  InvoicesRepository._internal();

  static final InvoicesRepository instance = InvoicesRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, CustomerProductPrice>> getCustomerProductPrices(
    String customerId,
  ) async {
    final rows = await _supabase.rpc(
      'get_customer_product_prices',
      params: {
        'p_customer_id': customerId,
      },
    );

    return {
      for (final row in (rows as List))
        (row as Map<String, dynamic>)['product_id'] as String:
            CustomerProductPrice.fromJson(row),
    };
  }

  Future<InvoiceRecordModel> issueInvoice({
    required String customerId,
    required List<InvoiceLineInput> items,
    required double discountAmount,
    required bool isCashSale,
    required double paidNow,
    PaymentMethod? paymentMethod,
    List<PaymentSplitEntry>? payments,
    String? notes,
  }) async {
    final row = await _supabase.rpc(
      'issue_invoice_v4',
      params: {
        'p_customer_id': customerId,
        'p_items': items.map((item) => item.toRpcJson()).toList(),
        'p_discount_amount': discountAmount,
        'p_sale_type': isCashSale ? 'cash' : 'credit',
        'p_paid_now': paidNow,
        'p_payment_method': paymentMethod?.backendValue,
        'p_notes': notes,
        if (payments != null && payments.isNotEmpty)
          'p_payments': payments.map((p) => p.toRpcJson()).toList(),
      },
    );

    return InvoiceRecordModel.fromSupabaseRow(
      row as Map<String, dynamic>,
    );
  }

  Future<void> editInvoice({
    required String invoiceId,
    required List<InvoiceItemDraft> items,
    required double discountAmount,
    required String reason,
    String? notes,
  }) async {
    await _supabase.rpc(
      'edit_invoice_v2',
      params: {
        'p_invoice_id': invoiceId,
        'p_items': items.map((item) => item.toRpcJson()).toList(),
        'p_discount_amount': discountAmount,
        'p_notes': notes,
        'p_reason': reason,
      },
    );
  }

  Future<void> collectAgainstInvoice({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    await _supabase.rpc(
      'collect_specific_invoice_payment',
      params: {
        'p_invoice_id': invoiceId,
        'p_amount': amount,
        'p_payment_method': method.backendValue,
        'p_notes': notes,
      },
    );
  }

  Future<void> releaseInvoiceOverpayment({
    required String invoiceId,
    required double newPaid,
  }) async {
    await _supabase.rpc(
      'release_invoice_overpayment',
      params: {
        'p_invoice_id': invoiceId,
        'p_new_paid': newPaid,
      },
    );
  }

  Future<void> refundCustomerCredit({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    await _supabase.rpc(
      'refund_customer_credit',
      params: {
        'p_customer_id': customerId,
        'p_amount': amount,
        'p_payment_method': paymentMethod,
        'p_notes': notes,
      },
    );
  }

  Future<double> getInvoiceApplicableCredit(String invoiceId) async {
    final result = await _supabase.rpc(
      'get_invoice_applicable_credit',
      params: {'p_invoice_id': invoiceId},
    );
    return double.tryParse(result.toString()) ?? 0;
  }

  Future<void> applyCustomerCreditToInvoice({
    required String invoiceId,
    required double amount,
  }) async {
    await _supabase.rpc(
      'apply_customer_credit_to_invoice',
      params: {
        'p_invoice_id': invoiceId,
        'p_amount': amount,
      },
    );
  }

  Future<List<InvoiceProductSearchResult>> searchInvoicesByProduct(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final rows = await _supabase.rpc(
      'search_invoices_by_product',
      params: {'p_query': trimmed, 'p_limit': 30},
    );
    return (rows as List<dynamic>)
        .map((row) =>
            InvoiceProductSearchResult.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceProductSearchResult>> searchCustomerInvoiceItems({
    required String customerId,
    required String customerName,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final pattern = trimmed
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');

    final rows = await _supabase
        .from('invoice_items')
        .select(
          'id, product_name, unit_price, quantity, '
          'invoices!inner(id, code, customer_id, invoice_date)',
        )
        .eq('invoices.customer_id', customerId)
        .ilike('product_name', '%$pattern%')
        .limit(100);

    final results = <InvoiceProductSearchResult>[];
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final invoice = map['invoices'];
      if (invoice is! Map) continue;
      final quantity = (map['quantity'] as num).toInt();
      results.add(
        InvoiceProductSearchResult(
          invoiceItemId: map['id'] as String,
          invoiceId: invoice['id'] as String,
          invoiceCode: invoice['code'] as String,
          invoiceDate:
              DateTime.parse(invoice['invoice_date'] as String).toLocal(),
          customerId: customerId,
          customerName: customerName,
          productName: map['product_name'] as String? ?? '',
          quantity: quantity,
          unitPrice: (map['unit_price'] as num).toDouble(),
          returnedQuantity: 0,
          returnableQuantity: quantity,
        ),
      );
    }
    results.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return results;
  }

  Future<List<DailyInvoiceSummary>> getDailyInvoiceSummaries({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _supabase
        .from('invoices')
        .select('id, code, invoice_date, total_amount, paid_now, status, '
            'customers(name)')
        .gte('invoice_date', from.toUtc().toIso8601String())
        .lt('invoice_date', to.toUtc().toIso8601String())
        .order('invoice_date', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => DailyInvoiceSummary.fromJson(row as Map<String, dynamic>))
        .toList();
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

    final rows = await query.order(
      'invoice_date',
      ascending: false,
    );

    return (rows as List)
        .map(
          (row) => InvoiceRecordModel.fromSupabaseRow(
            row as Map<String, dynamic>,
          ),
        )
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
        .order(
          'invoice_date',
          ascending: false,
        );

    return (rows as List)
        .map(
          (row) => InvoiceRecordModel.fromSupabaseRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<InvoiceFullDetail> getInvoiceDetailByCode(
    String code,
  ) async {
    final invoice =
        await _supabase.from('invoices').select().eq('code', code).single();

    final invoiceId = invoice['id'] as String;

    String? creatorName;
    final createdBy = invoice['created_by'] as String?;
    if (createdBy != null) {
      final creatorRow = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', createdBy)
          .maybeSingle();
      creatorName = creatorRow?['name'] as String?;
    }

    final itemRows = await _supabase
        .from('invoice_items')
        .select(
          'id, product_id, product_name, unit_price, quantity, line_total',
        )
        .eq('invoice_id', invoiceId);

    final items = (itemRows as List).map((row) {
      final item = row as Map<String, dynamic>;

      return InvoiceItemRow(
        id: item['id'] as String,
        productId: item['product_id'] as String?,
        productName: item['product_name'] as String? ?? '',
        unitPrice: (item['unit_price'] as num).toDouble(),
        quantity: (item['quantity'] as num).toInt(),
        lineTotal: (item['line_total'] as num).toDouble(),
      );
    }).toList();

    String? lastEditReason;
    try {
      final editRow = await _supabase
          .from('invoice_edit_history')
          .select('reason')
          .eq('invoice_id', invoiceId)
          .order('edited_at', ascending: false)
          .limit(1)
          .maybeSingle();
      lastEditReason = editRow?['reason'] as String?;
    } catch (_) {
      lastEditReason = null;
    }

    return InvoiceFullDetail(
      id: invoiceId,
      code: invoice['code'] as String,
      customerId: invoice['customer_id'] as String,
      date: DateTime.parse(invoice['invoice_date'] as String),
      subtotal: (invoice['subtotal'] as num).toDouble(),
      discountPercent: (invoice['discount_percent'] as num?)?.toDouble() ?? 0,
      discountAmount: (invoice['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (invoice['total_amount'] as num).toDouble(),
      paidNow: (invoice['paid_now'] as num).toDouble(),
      statusLabel: _statusLabelFromDb(
        invoice['status'] as String?,
      ),
      notes: invoice['notes'] as String?,
      items: items,
      creatorType: invoice['creator_type'] as String?,
      creatorName: creatorName,
      lastEditReason: lastEditReason,
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
        .select('product_id, product_name, unit_price, quantity, '
            'invoices!inner(id, customer_id, invoice_date), '
            'products(deleted_at)')
        .eq('invoices.customer_id', customerId);

    final byProduct = <String, List<Map<String, dynamic>>>{};
    final deletedProducts = <String>{};

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final productId = map['product_id'] as String?;

      if (productId == null || productId.trim().isEmpty) {
        continue;
      }

      byProduct.putIfAbsent(productId, () => []).add(map);

      final productData = map['products'];
      if (productData is Map && productData['deleted_at'] != null) {
        deletedProducts.add(productId);
      }
    }

    final stats = <ProductPurchaseStat>[];

    byProduct.forEach((productId, items) {
      items.sort((a, b) {
        final da = DateTime.parse(
          (a['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
        );
        final db = DateTime.parse(
          (b['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
        );

        return db.compareTo(da);
      });

      final latest = items.first;

      final lastDate = DateTime.parse(
        (latest['invoices'] as Map<String, dynamic>)['invoice_date'] as String,
      );

      final distinctInvoiceIds = items
          .map((item) =>
              (item['invoices'] as Map<String, dynamic>)['id'] as String)
          .toSet();

      final productName = latest['product_name'] as String? ?? '';

      stats.add(
        ProductPurchaseStat(
          productId: productId,
          productName: productName,
          lastPrice: (latest['unit_price'] as num).toDouble(),
          lastPurchaseDate: lastDate,
          timesPurchased: distinctInvoiceIds.length,
          isDeleted: deletedProducts.contains(productId),
        ),
      );
    });

    return stats;
  }
}

class DailyInvoiceSummary {
  final String id;
  final String code;
  final DateTime date;
  final double amount;
  final double paidAmount;
  final InvoiceStatus status;
  final String customerName;

  const DailyInvoiceSummary({
    required this.id,
    required this.code,
    required this.date,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.customerName,
  });

  factory DailyInvoiceSummary.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    return DailyInvoiceSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      date: DateTime.parse(json['invoice_date'] as String).toLocal(),
      amount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_now'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'deferred'),
        orElse: () => InvoiceStatus.deferred,
      ),
      customerName: customer?['name'] as String? ?? '',
    );
  }
}
