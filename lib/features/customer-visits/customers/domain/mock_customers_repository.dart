import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/collection_record_model.dart';
import 'models/customer_model.dart';
import 'models/customer_status.dart';
import 'models/invoice_record_model.dart';

class MockCustomersRepository {
  MockCustomersRepository._internal();

  static final MockCustomersRepository instance =
      MockCustomersRepository._internal();

  static const String _storageKey = 'mock_customers';
  static const String _invoicesStorageKey = 'mock_customer_invoices';

  static const String _collectionsStorageKey = 'mock_customer_collections';
  final List<CollectionRecordModel> _collections = [];

  final List<CustomerModel> _customers = [];
  final ValueNotifier<List<CustomerModel>> customersNotifier =
      ValueNotifier<List<CustomerModel>>(<CustomerModel>[]);

  final Map<String, List<InvoiceRecordModel>> _invoicesByCustomer = {};

  bool _initialized = false;

  List<CustomerModel> get customers => _customers;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      _customers
        ..clear()
        ..addAll(raw.map((entry) => CustomerModel.fromJsonString(entry)));
    } else {
      _customers
        ..clear()
        ..addAll(_seedCustomers);
      await _persist(prefs);
    }

    _loadInvoices(prefs);
    _loadCollections(prefs);

    customersNotifier.value = List<CustomerModel>.from(_customers);
    _initialized = true;
  }

  Future<void> resetForTests() async {
    _initialized = false;
    _customers.clear();
    _invoicesByCustomer.clear();
    customersNotifier.value = <CustomerModel>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_invoicesStorageKey);
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await initialize();
    _customers.insert(0, customer);
    await _persist();
    customersNotifier.value = List<CustomerModel>.from(_customers);
  }

  Future<void> updateCustomerStatus(
      String customerId, CustomerStatus status) async {
    await initialize();
    final index =
        _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) return;

    _customers[index] = _customers[index].copyWith(status: status);
    await _persist();
    customersNotifier.value = List<CustomerModel>.from(_customers);
  }

  /// يعدّل رصيد العميل الحالي. [delta] موجب = دين جديد (فاتورة)،
  /// سالب = سداد (تحصيل). لو [isCollection] بقى true بيحدّث كمان
  /// تاريخ آخر تحصيل للنهاردة. [collectedAmount] لازم تتبعت صراحة لما
  /// الكاش المحصّل مش مساوي لـ -delta (زي الدفع الجزئي وقت الفاتورة).
  Future<void> adjustBalance(
      String customerId,
      double delta, {
        bool isCollection = false,
        double? collectedAmount,
        CollectionSource collectionSource = CollectionSource.oldDebtPayment,
      }) async {
    await initialize();
    final index =
    _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) return;

    final current = _customers[index];
    final newBalance = current.currentBalance + delta;
    final clamped = newBalance < 0 ? 0.0 : newBalance;

    _customers[index] = current.copyWith(
      currentBalance: clamped,
      lastCollectionDate:
      isCollection ? DateTime.now() : current.lastCollectionDate,
    );

    final effectiveCollected =
        collectedAmount ?? (isCollection && delta < 0 ? -delta : null);
    if (effectiveCollected != null && effectiveCollected > 0) {
      _collections.add(CollectionRecordModel(
        customerId: customerId,
        amount: effectiveCollected,
        date: DateTime.now(),
        source: collectionSource,
      ));
      final prefs = await SharedPreferences.getInstance();
      await _persistCollections(prefs);
    }

    await _persist();
    customersNotifier.value = List<CustomerModel>.from(_customers);
  }

  List<InvoiceRecordModel> getAllInvoicesInRange(DateTime start, DateTime end) {
    final result = <InvoiceRecordModel>[];
    for (final list in _invoicesByCustomer.values) {
      result.addAll(
        list.where((inv) => !inv.date.isBefore(start) && inv.date.isBefore(end)),
      );
    }
    return result;
  }

  List<CollectionRecordModel> getAllCollectionsInRange(
      DateTime start, DateTime end) {
    return _collections
        .where((c) => !c.date.isBefore(start) && c.date.isBefore(end))
        .toList();
  }

  void _loadCollections(SharedPreferences prefs) {
    final raw = prefs.getStringList(_collectionsStorageKey) ?? const [];
    _collections
      ..clear()
      ..addAll(raw.map(
            (e) => CollectionRecordModel.fromJson(jsonDecode(e) as Map<String, dynamic>),
      ));
  }

  Future<void> _persistCollections(SharedPreferences prefs) async {
    await prefs.setStringList(
      _collectionsStorageKey,
      _collections.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  /// يسجل فاتورة جديدة لعميل معين — بيتخزن عشان نقدر نحسب منه
  /// "متوسط الطلب" الحقيقي، ولاحقًا يتستخدم في كشف الحساب.
  Future<void> addInvoice(String customerId, InvoiceRecordModel invoice) async {
    await initialize();
    final list = _invoicesByCustomer.putIfAbsent(customerId, () => []);
    list.insert(0, invoice);
    final prefs = await SharedPreferences.getInstance();
    await _persistInvoices(prefs);
    customersNotifier.value = List<CustomerModel>.from(_customers);
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

  CustomerModel? getCustomerById(String id) {
    return _customers.firstWhere(
      (customer) => customer.id == id,
      orElse: () => const CustomerModel(
        id: '',
        name: '',
        code: '',
        area: '',
        category: '',
        visitsThisMonth: 0,
      ),
    );
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

  Future<void> _persist([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final encoded =
        _customers.map((customer) => customer.toJsonString()).toList();
    await prefs.setStringList(_storageKey, encoded);
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

  static final List<CustomerModel> _seedCustomers = [
    const CustomerModel(
      id: '1',
      name: 'صيدلية النور',
      code: 'C-1042',
      area: 'المنصورة',
      category: 'صيدلية بيطرية',
      status: CustomerStatus.active,
      visitsThisMonth: 4,
      phone: '01012345671',
      address: 'المنصورة — طلخا',
      creditLimit: 5000,
      currentBalance: 2000,
    ),
    const CustomerModel(
      id: '2',
      name: 'عيادة الشفاء البيطرية',
      code: 'C-1043',
      area: 'طلخا',
      category: 'عيادة',
      status: CustomerStatus.needsFollowUp,
      visitsThisMonth: 2,
      phone: '01012345672',
      address: 'المنصورة — ميت حضر',
      creditLimit: 3000,
      currentBalance: 1200,
    ),
    const CustomerModel(
      id: '3',
      name: 'مزرعة الدلتا للدواجن',
      code: 'C-1044',
      area: 'شربين',
      category: 'مزرعة دواجن',
      status: CustomerStatus.stopped,
      visitsThisMonth: 0,
      phone: '01012345673',
      address: 'المنصورة — شربين',
      creditLimit: 8000,
      currentBalance: 0,
    ),
    const CustomerModel(
      id: '4',
      name: 'صيدلية الأمل',
      code: 'C-1045',
      area: 'ميت غمر',
      category: 'صيدلية بيطرية',
      status: CustomerStatus.active,
      visitsThisMonth: 3,
      phone: '01012345674',
      address: 'المنصورة — ميت غمر',
      creditLimit: 4000,
      currentBalance: 900,
    ),
    const CustomerModel(
      id: '5',
      name: 'مزرعة الفا لارج',
      code: 'C-1046',
      area: 'طلخا',
      category: 'مزرعة لارج',
      status: CustomerStatus.needsFollowUp,
      visitsThisMonth: 1,
      phone: '01012345675',
      address: 'المنصورة — طلخا',
      creditLimit: 6000,
      currentBalance: 3300,
    ),
  ];
}
