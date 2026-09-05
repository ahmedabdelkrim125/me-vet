import 'visit_status.dart';

class VisitHistoryModel {
  final String visitId;
  final String customerId;
  final String customerName;
  final String area;
  final RouteVisitStatus status;
  final DateTime scheduledAt;
  final DateTime statusUpdatedAt;

  const VisitHistoryModel({
    required this.visitId,
    required this.customerId,
    required this.customerName,
    required this.area,
    required this.status,
    required this.scheduledAt,
    required this.statusUpdatedAt,
  });

  VisitHistoryModel copyWith({
    String? customerName,
    String? area,
    RouteVisitStatus? status,
    DateTime? statusUpdatedAt,
  }) {
    return VisitHistoryModel(
      visitId: visitId,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      area: area ?? this.area,
      status: status ?? this.status,
      scheduledAt: scheduledAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitId': visitId,
      'customerId': customerId,
      'customerName': customerName,
      'area': area,
      'status': status.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'statusUpdatedAt': statusUpdatedAt.toIso8601String(),
    };
  }

  factory VisitHistoryModel.fromJson(Map<String, dynamic> json) {
    return VisitHistoryModel(
      visitId: json['visitId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      area: json['area'] as String,
      status: RouteVisitStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RouteVisitStatus.pending,
      ),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      statusUpdatedAt: DateTime.parse(json['statusUpdatedAt'] as String),
    );
  }
}
