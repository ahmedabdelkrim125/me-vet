import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import '../../../domain/models/visit_status.dart';

Color routeStatusColor(RouteVisitStatus status) {
  switch (status) {
    case RouteVisitStatus.pending:
      return AppColors.navInactive;
    case RouteVisitStatus.completed:
      return AppColors.primaryGreen;
    case RouteVisitStatus.sold:
      return AppColors.statBlue;
    case RouteVisitStatus.noOrder:
      return AppColors.statOrange;
    case RouteVisitStatus.notReached:
      return AppColors.statusNotReached;
  }
}
