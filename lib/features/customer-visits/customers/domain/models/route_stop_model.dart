import 'visit_status.dart';

class RouteStopModel {
  final int order;
  final String customerName;
  final String area;
  final RouteVisitStatus status;

  const RouteStopModel({
    required this.order,
    required this.customerName,
    required this.area,
    required this.status,
  });
}
