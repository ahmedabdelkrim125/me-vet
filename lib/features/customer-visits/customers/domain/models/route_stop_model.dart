import 'visit_status.dart';

class RouteStopModel {
  final String? visitId;
  final String customerId;
  final int order;
  final String customerName;
  final String area;
  final RouteVisitStatus status;
  final DateTime? scheduledAt;
  final DateTime? statusUpdatedAt;

  const RouteStopModel({
    this.visitId,
    required this.customerId,
    required this.order,
    required this.customerName,
    required this.area,
    required this.status,
    this.scheduledAt,
    this.statusUpdatedAt,
  });

  RouteStopModel copyWith({
    String? visitId,
    String? customerId,
    int? order,
    String? customerName,
    String? area,
    RouteVisitStatus? status,
    DateTime? scheduledAt,
    DateTime? statusUpdatedAt,
  }) {
    return RouteStopModel(
      visitId: visitId ?? this.visitId,
      customerId: customerId ?? this.customerId,
      order: order ?? this.order,
      customerName: customerName ?? this.customerName,
      area: area ?? this.area,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }
}
