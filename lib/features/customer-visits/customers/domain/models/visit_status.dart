enum RouteVisitStatus { pending, completed, sold, noOrder, notReached }

extension RouteVisitStatusX on RouteVisitStatus {
  String get label {
    switch (this) {
      case RouteVisitStatus.pending:
        return 'لسه';
      case RouteVisitStatus.completed:
        return 'تمت';
      case RouteVisitStatus.sold:
        return 'بيع';
      case RouteVisitStatus.noOrder:
        return 'بدون طلب';
      case RouteVisitStatus.notReached:
        return 'لم يوصل';
    }
  }

  String get dbValue {
    switch (this) {
      case RouteVisitStatus.pending:
        return 'pending';
      case RouteVisitStatus.completed:
        return 'completed';
      case RouteVisitStatus.sold:
        return 'sold';
      case RouteVisitStatus.noOrder:
        return 'no_order';
      case RouteVisitStatus.notReached:
        return 'not_reached';
    }
  }
}

RouteVisitStatus routeVisitStatusFromDb(String? value) {
  switch (value) {
    case 'completed':
      return RouteVisitStatus.completed;
    case 'sold':
      return RouteVisitStatus.sold;
    case 'no_order':
      return RouteVisitStatus.noOrder;
    case 'not_reached':
      return RouteVisitStatus.notReached;
    case 'pending':
    default:
      return RouteVisitStatus.pending;
  }
}
