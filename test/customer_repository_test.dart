import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/mock_customers_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/customer_model.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/customer_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockCustomersRepository.instance.resetForTests();
  });

  test('new customers default to needs follow-up and can be filtered by status',
      () async {
    await MockCustomersRepository.instance.initialize();

    await MockCustomersRepository.instance.addCustomer(
      const CustomerModel(
        id: '10',
        name: 'اختبار',
        code: 'C-1000',
        area: 'المنصورة',
        category: 'صيدلية',
        visitsThisMonth: 0,
      ),
    );

    final customer = MockCustomersRepository.instance.getCustomerById('10');
    expect(customer, isNotNull);
    expect(customer!.status, CustomerStatus.needsFollowUp);

    final activeCustomers = MockCustomersRepository.instance.getCustomers(
      status: CustomerStatus.active,
    );
    final followUpCustomers = MockCustomersRepository.instance.getCustomers(
      status: CustomerStatus.needsFollowUp,
    );

    expect(activeCustomers.any((item) => item.id == '10'), isFalse);
    expect(followUpCustomers.any((item) => item.id == '10'), isTrue);
  });

  test('updating customer status refreshes filtered lists', () async {
    await MockCustomersRepository.instance.initialize();

    await MockCustomersRepository.instance
        .updateCustomerStatus('1', CustomerStatus.stopped);

    final activeCustomers = MockCustomersRepository.instance.getCustomers(
      status: CustomerStatus.active,
    );
    final stoppedCustomers = MockCustomersRepository.instance.getCustomers(
      status: CustomerStatus.stopped,
    );

    expect(activeCustomers.any((item) => item.id == '1'), isFalse);
    expect(stoppedCustomers.any((item) => item.id == '1'), isTrue);
  });
}
