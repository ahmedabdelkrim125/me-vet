import 'models/customer_model.dart';
import 'models/customer_status.dart';

class MockCustomersRepository {
  MockCustomersRepository._internal();

  static final MockCustomersRepository instance =
      MockCustomersRepository._internal();

  final List<CustomerModel> customers = [
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
      status: CustomerStatus.stalled,
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

  void addCustomer(CustomerModel customer) => customers.insert(0, customer);
}
