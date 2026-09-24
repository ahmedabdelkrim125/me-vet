import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../customer-visits/customers/domain/models/customer_model.dart';
import '../../customer-visits/customers/domain/models/invoice_line_input.dart';
import '../../customer_account/domain/entities/payment_method.dart';

/// أداء مندوب واحد — نتيجة `get_rep_performance_stats`.
class RepPerformanceStats {
  final String repId;
  final String repName;
  final String phone;
  final bool isActive;
  final DateTime? lastLoginAt;
  final int assignedCustomers;
  final int visitedCustomers;
  final int visitCount;
  final int completedVisits;
  final int soldVisits;
  final int noOrderVisits;
  final int notReachedVisits;
  final int pendingVisits;
  final int customersWithInvoices;
  final int invoiceCount;
  final double totalSales;
  final int totalUnitsSold;
  final double totalCollections;
  final int returnCount;
  final double totalReturns;
  final double totalExpenses;
  final double outstandingInvoiceAmount;

  const RepPerformanceStats({
    required this.repId,
    required this.repName,
    required this.phone,
    required this.isActive,
    this.lastLoginAt,
    required this.assignedCustomers,
    required this.visitedCustomers,
    required this.visitCount,
    required this.completedVisits,
    required this.soldVisits,
    required this.noOrderVisits,
    required this.notReachedVisits,
    required this.pendingVisits,
    required this.customersWithInvoices,
    required this.invoiceCount,
    required this.totalSales,
    required this.totalUnitsSold,
    required this.totalCollections,
    required this.returnCount,
    required this.totalReturns,
    required this.totalExpenses,
    required this.outstandingInvoiceAmount,
  });

  factory RepPerformanceStats.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return RepPerformanceStats(
      repId: json['rep_id'] as String,
      repName: json['rep_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      assignedCustomers: i('assigned_customers'),
      visitedCustomers: i('visited_customers'),
      visitCount: i('visit_count'),
      completedVisits: i('completed_visits'),
      soldVisits: i('sold_visits'),
      noOrderVisits: i('no_order_visits'),
      notReachedVisits: i('not_reached_visits'),
      pendingVisits: i('pending_visits'),
      customersWithInvoices: i('customers_with_invoices'),
      invoiceCount: i('invoice_count'),
      totalSales: d('total_sales'),
      totalUnitsSold: i('total_units_sold'),
      totalCollections: d('total_collections'),
      returnCount: i('return_count'),
      totalReturns: d('total_returns'),
      totalExpenses: d('total_expenses'),
      outstandingInvoiceAmount: d('outstanding_invoice_amount'),
    );
  }
}

/// كل نداءات Supabase الخاصة بصلاحيات الأونر الإضافية: مديونية قديمة،
/// فاتورة تاريخية، حذف عميل نهائي، وتقارير أداء المناديب.
///
/// إدارة بيانات المندوب نفسها (اسم/هاتف/PIN/تفعيل) موجودة بالفعل في
/// [OwnerService] عن طريق Edge Function `manage-rep` ومش متكررة هنا.
class AdminActionsService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final rows = await _supabase.from('customers').select().order('name');
      return (rows as List)
          .map((row) => CustomerModel.fromSupabaseRow(
              Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<List<RepPerformanceStats>> getRepPerformanceStats() async {
    try {
      final rows = await _supabase.rpc('get_rep_performance_stats');
      return (rows as List)
          .map((row) => RepPerformanceStats.fromJson(
              Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<void> addOldDebt({
    required String customerId,
    required double amount,
    required DateTime effectiveAt,
    String? notes,
  }) async {
    try {
      await _supabase.rpc('admin_add_old_debt', params: {
        'p_customer_id': customerId,
        'p_amount': amount,
        'p_effective_at': effectiveAt.toUtc().toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'p_notes': notes.trim(),
      });
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<void> issueHistoricalInvoice({
    required String customerId,
    required List<InvoiceLineInput> items,
    required DateTime invoiceDate,
    double discountPercent = 0,
    required bool isCashSale,
    double paidNow = 0,
    PaymentMethod? paymentMethod,
    String? notes,
  }) async {
    try {
      await _supabase.rpc('admin_issue_historical_invoice', params: {
        'p_customer_id': customerId,
        'p_items': items.map((item) => item.toRpcJson()).toList(),
        'p_invoice_date': invoiceDate.toUtc().toIso8601String(),
        'p_discount_percent': discountPercent,
        'p_sale_type': isCashSale ? 'cash' : 'credit',
        'p_paid_now': paidNow,
        if (paymentMethod != null)
          'p_payment_method': paymentMethod.backendValue,
        if (notes != null && notes.trim().isNotEmpty) 'p_notes': notes.trim(),
      });
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  /// حذف نهائي لا يمكن التراجع عنه — كل فواتير العميل وزياراته وتحصيلاته
  /// وكل ما هو مرتبط به بيتمسح فعليًا من قاعدة البيانات.
  Future<void> deleteCustomerPermanently(String customerId) async {
    try {
      await _supabase.rpc('admin_delete_customer', params: {
        'p_customer_id': customerId,
      });
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }
}
