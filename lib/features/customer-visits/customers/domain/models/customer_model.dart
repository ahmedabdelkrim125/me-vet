import 'customer_status.dart';

class CustomerModel {
  final String id;
  final String name;
  final String code;
  final String area;
  final String category;
  final CustomerStatus status;
  final int visitsThisMonth;
  final String phone;
  final String address;
  final double creditLimit;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.code,
    required this.area,
    required this.category,
    required this.status,
    required this.visitsThisMonth,
    this.phone = '',
    this.address = '',
    this.creditLimit = 0,
  });
}
