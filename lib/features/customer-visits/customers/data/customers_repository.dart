import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/collection_record_model.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/customer_status.dart';

class CustomersRepository {
  CustomersRepository._internal();

  static final CustomersRepository instance = CustomersRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  final List<CustomerModel> _customers = [];
  final ValueNotifier<List<CustomerModel>> customersNotifier =
      ValueNotifier<List<CustomerModel>>(<CustomerModel>[]);

  bool _initialized = false;

  List<CustomerModel> get customers => _customers;

  Future<void> initialize() async {
    if (_initialized) return;
    await _fetchCustomers();
    _initialized = true;
  }

  
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

  void reset() {
    _initialized = false;
    _customers.clear();
    customersNotifier.value = <CustomerModel>[];
  }

  Future<void> resetForTests() async {
    reset();
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

  Future<void> updateCustomer(CustomerModel customer) async {
    await _supabase.from('customers').update({
      'name': customer.name,
      'area': customer.area,
      'category': customer.category,
      'phone': customer.phone,
      'address': customer.address,
      'credit_limit': customer.creditLimit,
      'latitude': customer.latitude,
      'longitude': customer.longitude,
    }).eq('id', customer.id);
    await _fetchCustomers();
  }

  Future<void> updateCustomerNotes(String customerId, String notes) async {
    await _supabase
        .from('customers')
        .update({'notes': notes}).eq('id', customerId);
    await _fetchCustomers();
  }

  Future<void> deleteCustomer(String customerId) async {
    await _supabase.from('customers').delete().eq('id', customerId);
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
