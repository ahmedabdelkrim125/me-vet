import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/collection_record_model.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/customer_status.dart';
import '../domain/models/invoice_record_model.dart';

/// Supabase-backed customers repository — بيحل محل `CustomersRepository`.
///
/// الهجرة بتحصل على مرحلتين:
/// - بيانات العميل نفسه (الاسم، الحالة، الرصيد، حد الائتمان...) → جدول
///   `customers` في Supabase. مشترك بين كل الأجهزة ومحكوم بـ RLS: كل مندوب
///   يشوف/يعدّل عملاءه بس، والأونر يشوف الكل.
/// - الفواتير والتحصيلات (getInvoices/addInvoice/getAllInvoicesInRange)
///   لسه محلية مؤقتًا (SharedPreferences) لحد ما نشتغل على فيتشر الفواتير
///   ويتهاجر جدولي `invoices`/`collections` هما كمان. الميثودز دي متعلّم
///   عليها TODO تحت وواضح إنها مرحلة انتقالية.
class CustomersRepository {
  CustomersRepository._internal();

  static final CustomersRepository instance = CustomersRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const String _invoicesStorageKey = 'mock_customer_invoices';

  final List<CustomerModel> _customers = [];
  final ValueNotifier<List<CustomerModel>> customersNotifier =
      ValueNotifier<List<CustomerModel>>(<CustomerModel>[]);

  final Map<String, List<InvoiceRecordModel>> _invoicesByCustomer = {};

  bool _initialized = false;

  List<CustomerModel> get customers => _customers;

  Future<void> initialize() async {
    if (_initialized) return;
    await _fetchCustomers();

    // TODO(invoices-feature): هتتشال لما invoices تتهاجر لـ Supabase.
    final prefs = await SharedPreferences.getInstance();
    _loadInvoices(prefs);

    _initialized = true;
  }

  /// يعيد تحميل قائمة العملاء من Supabase (يُستخدم داخليًا بعد أي تعديل،
  /// ومتاح كمان لو حابب تعمل pull-to-refresh من الشاشة).
  Future<void> refresh() => _fetchCustomers();

  Future<void> _fetchCustomers() async {
    final rows = await _supabase
        .from('customers')
        .select()
        .order('created_at', ascending: false);
    _customers
      ..clear()
      ..addAll((rows as List).map(
          (row) => CustomerModel.fromSupabaseRow(row as Map<String, dynamic>)));
    customersNotifier.value = List<CustomerModel>.from(_customers);
  }

  Future<void> resetForTests() async {
    _initialized = false;
    _customers.clear();
    _invoicesByCustomer.clear();
    customersNotifier.value = <CustomerModel>[];
  }

  Future<void> addCustomer(CustomerModel customer) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('customers').insert({
      ...customer.toSupabaseInsert(),
      if (userId != null) 'assigned_rep_id': userId,
    });
    await _fetchCustomers();
  }

  Future<void> updateCustomerStatus(
      String customerId, CustomerStatus status) async {
    await _supabase
        .from('customers')
        .update({'status': status.dbValue}).eq('id', customerId);
    await _fetchCustomers();
  }

  /// يعدّل رصيد العميل الحالي. [delta] موجب = دين جديد (فاتورة)، سالب =
  /// سداد (تحصيل). عن طريق RPC `adjust_customer_balance` عشان تحديث
  /// الرصيد + تسجيل التحصيل (لو موجود) يحصلوا مع بعض في عملية واحدة.
  Future<void> adjustBalance(
    String customerId,
    double delta, {
    bool isCollection = false,
    double? collectedAmount,
    CollectionSource collectionSource = CollectionSource.oldDebtPayment,
  }) async {
    final effectiveCollected =
        collectedAmount ?? (isCollection && delta < 0 ? -delta : null);

    await _supabase.rpc('adjust_customer_balance', params: {
      'p_customer_id': customerId,
      'p_delta': delta,
      'p_is_collection': isCollection,
      'p_collected_amount': effectiveCollected,
      'p_collection_source': collectionSource.dbValue,
    });
    await _fetchCustomers();
  }

  CustomerModel? getCustomerById(String id) {
    for (final customer in _customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  List<CustomerModel> getCustomers(
      {CustomerStatus? status, String query = ''}) {
    final normalizedQuery = query.trim().toLowerCase();
    return _customers.where((customer) {
      final matchesStatus = status == null || customer.status == status;
      final matchesQuery = normalizedQuery.isEmpty ||
          customer.name.toLowerCase().contains(normalizedQuery) ||
          customer.code.toLowerCase().contains(normalizedQuery);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  int countForStatus(CustomerStatus? status) {
    return getCustomers(status: status).length;
  }

  // ---------------------------------------------------------------------
  // TODO(invoices-feature): الجزء ده هيتنقل لجدول `invoices` في Supabase
  // لما نشتغل على فرع الفواتير. لحد وقتها لسه محلي (SharedPreferences)
  // بالظبط زي ما كان في CustomersRepository.
  // ---------------------------------------------------------------------

  Future<void> addInvoice(String customerId, InvoiceRecordModel invoice) async {
    final list = _invoicesByCustomer.putIfAbsent(customerId, () => []);
    list.insert(0, invoice);
    final prefs = await SharedPreferences.getInstance();
    await _persistInvoices(prefs);
  }

  List<InvoiceRecordModel> getInvoices(String customerId) {
    return List<InvoiceRecordModel>.from(
        _invoicesByCustomer[customerId] ?? const []);
  }

  /// متوسط قيمة الفاتورة لعميل معين، أو صفر لو مفيش فواتير مسجلة له لسه.
  double getAverageOrder(String customerId) {
    final invoices = _invoicesByCustomer[customerId];
    if (invoices == null || invoices.isEmpty) return 0;
    final total = invoices.fold<double>(0, (sum, inv) => sum + inv.amount);
    return total / invoices.length;
  }

  List<InvoiceRecordModel> getAllInvoicesInRange(DateTime start, DateTime end) {
    final result = <InvoiceRecordModel>[];
    for (final list in _invoicesByCustomer.values) {
      result.addAll(
        list.where(
            (inv) => !inv.date.isBefore(start) && inv.date.isBefore(end)),
      );
    }
    return result;
  }

  void _loadInvoices(SharedPreferences prefs) {
    final raw = prefs.getString(_invoicesStorageKey);
    _invoicesByCustomer.clear();
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    decoded.forEach((customerId, list) {
      _invoicesByCustomer[customerId] = (list as List)
          .map((e) => InvoiceRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _persistInvoices(SharedPreferences prefs) async {
    final encoded = _invoicesByCustomer.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_invoicesStorageKey, jsonEncode(encoded));
  }

  // ---------------------------------------------------------------------
  // Collections — الكتابة بقت حقيقية (عن طريق adjustBalance → RPC)، والقراءة
  // هنا بتيجي مباشرة من جدول `collections` في Supabase.
  // ---------------------------------------------------------------------

  Future<List<CollectionRecordModel>> getAllCollectionsInRange(
      DateTime start, DateTime end) async {
    final rows = await _supabase
        .from('collections')
        .select()
        .gte('collected_at', start.toIso8601String())
        .lt('collected_at', end.toIso8601String());
    return (rows as List)
        .map((row) =>
            CollectionRecordModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }
}
