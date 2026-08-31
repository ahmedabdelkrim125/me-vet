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
  final String notes;
  final double creditLimit;
  final double currentBalance;
  final DateTime? lastCollectionDate;
  final double averageOrder;

  /// إحداثيات دقيقة (GPS) لموقع العميل — لو null يبقى العنوان اتكتب يدوي
  /// من غير تحديد موقع، و"الموقع" في التفاصيل هيدور بالاسم مش الإحداثيات.
  final double? latitude;
  final double? longitude;
  final String? createdBy;

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
    this.notes = '',
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.lastCollectionDate,
    this.averageOrder = 0,
    this.latitude,
    this.longitude,
    this.createdBy,
  });

  bool get hasPreciseLocation => latitude != null && longitude != null;

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
    String? notes,
    double? creditLimit,
    double? currentBalance,
    DateTime? lastCollectionDate,
    double? averageOrder,
    double? latitude,
    double? longitude,
    String? createdBy,
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
      notes: notes ?? this.notes,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      lastCollectionDate: lastCollectionDate ?? this.lastCollectionDate,
      averageOrder: averageOrder ?? this.averageOrder,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
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
      'notes': notes,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'lastCollectionDate': lastCollectionDate?.toIso8601String(),
      'averageOrder': averageOrder,
      'latitude': latitude,
      'longitude': longitude,
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
      notes: json['notes'] as String? ?? '',
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      lastCollectionDate: json['lastCollectionDate'] == null
          ? null
          : DateTime.parse(json['lastCollectionDate'] as String),
      averageOrder: (json['averageOrder'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CustomerModel.fromJsonString(String raw) {
    return CustomerModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// يبني الموديل من صف جدول `customers` في Supabase (أعمدة snake_case).
  ///
  /// `visitsThisMonth` و `averageOrder` لسه مش متحسوبين من هنا (TODO):
  /// هيتوصّلوا بجدولي `customer_visits` و `invoices` لما فيتشرات الزيارات
  /// والفواتير تتهاجر لـ Supabase هي كمان.
  factory CustomerModel.fromSupabaseRow(Map<String, dynamic> row) {
    return CustomerModel(
      id: row['id'] as String,
      name: row['name'] as String,
      code: row['code'] as String,
      area: row['area'] as String? ?? '',
      category: row['category'] as String? ?? '',
      status: customerStatusFromDb(row['status'] as String?),
      visitsThisMonth: 0,
      phone: row['phone'] as String? ?? '',
      address: row['address'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      creditLimit: (row['credit_limit'] as num?)?.toDouble() ?? 0,
      currentBalance: (row['current_balance'] as num?)?.toDouble() ?? 0,
      lastCollectionDate: row['last_collection_date'] == null
          ? null
          : DateTime.parse(row['last_collection_date'] as String),
      averageOrder: 0,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      createdBy: row['created_by'] as String?,
    );
  }

  /// يجهّز الحقول اللي تُكتب فعليًا عند إضافة عميل جديد. `id` و `code`
  /// متعمّدين مش موجودين — الداتابيز بتولّدهم (uuid + trigger الكود التلقائي).
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'name': name,
      'area': area,
      'category': category,
      'status': status.dbValue,
      'phone': phone,
      'address': address,
      'notes': notes,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
