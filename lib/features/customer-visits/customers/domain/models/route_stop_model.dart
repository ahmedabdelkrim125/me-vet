import 'visit_status.dart';

class RouteStopModel {
  final String customerId;
  final int order;
  final String customerName;
  final String area;
  final RouteVisitStatus status;

  const RouteStopModel({
    required this.customerId,
    required this.order,
    required this.customerName,
    required this.area,
    required this.status,
  });

  RouteStopModel copyWith({
    String? customerId,
    int? order,
    String? customerName,
    String? area,
    RouteVisitStatus? status,
  }) {
    return RouteStopModel(
      customerId: customerId ?? this.customerId,
      order: order ?? this.order,
      customerName: customerName ?? this.customerName,
      area: area ?? this.area,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'order': order,
    'customerName': customerName,
    'area': area,
    'status': status.name,
  };

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      customerId: json['customerId'] as String,
      order: json['order'] as int,
      customerName: json['customerName'] as String,
      area: json['area'] as String,
      status: RouteVisitStatus.values.firstWhere(
            (v) => v.name == json['status'],
        orElse: () => RouteVisitStatus.pending,
      ),
    );
  }
}
