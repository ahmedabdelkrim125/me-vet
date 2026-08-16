import 'dart:convert';

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
  final double currentBalance;
  final DateTime? lastCollectionDate;
  final double averageOrder;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.code,
    required this.area,
    required this.category,
    this.status = CustomerStatus.needsFollowUp,
    required this.visitsThisMonth,
    this.phone = '',
    this.address = '',
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.lastCollectionDate,
    this.averageOrder = 0,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? code,
    String? area,
    String? category,
    CustomerStatus? status,
    int? visitsThisMonth,
    String? phone,
    String? address,
    double? creditLimit,
    double? currentBalance,
    DateTime? lastCollectionDate,
    double? averageOrder,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      area: area ?? this.area,
      category: category ?? this.category,
      status: status ?? this.status,
      visitsThisMonth: visitsThisMonth ?? this.visitsThisMonth,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      lastCollectionDate: lastCollectionDate ?? this.lastCollectionDate,
      averageOrder: averageOrder ?? this.averageOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'area': area,
      'category': category,
      'status': status.name,
      'visitsThisMonth': visitsThisMonth,
      'phone': phone,
      'address': address,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'lastCollectionDate': lastCollectionDate?.toIso8601String(),
      'averageOrder': averageOrder,
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      area: json['area'] as String,
      category: json['category'] as String,
      status: CustomerStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => CustomerStatus.needsFollowUp,
      ),
      visitsThisMonth: json['visitsThisMonth'] as int,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      lastCollectionDate: json['lastCollectionDate'] == null
          ? null
          : DateTime.parse(json['lastCollectionDate'] as String),
      averageOrder: (json['averageOrder'] as num?)?.toDouble() ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CustomerModel.fromJsonString(String raw) {
    return CustomerModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
