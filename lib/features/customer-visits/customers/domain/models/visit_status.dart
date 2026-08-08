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
}
