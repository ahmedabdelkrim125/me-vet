import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/customer_model.dart';
import 'models/customer_status.dart';

class MockCustomersRepository {
  MockCustomersRepository._internal();

  static final MockCustomersRepository instance =
      MockCustomersRepository._internal();

  static const String _storageKey = 'mock_customers';

  final List<CustomerModel> _customers = [];
  final ValueNotifier<List<CustomerModel>> customersNotifier =
      ValueNotifier<List<CustomerModel>>(<CustomerModel>[]);

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

    customersNotifier.value = List<CustomerModel>.from(_customers);
    _initialized = true;
  }

  Future<void> resetForTests() async {
    _initialized = false;
    _customers.clear();
    customersNotifier.value = <CustomerModel>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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
    ),
  ];
}
