import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import '../../../domain/models/visit_status.dart';

Color routeStatusColor(BuildContext context, RouteVisitStatus status) {
  switch (status) {
    case RouteVisitStatus.pending:
      return context.colors.textMuted;
    case RouteVisitStatus.completed:
      return context.colors.primary;
    case RouteVisitStatus.sold:
      return context.colors.statBlue;
    case RouteVisitStatus.noOrder:
      return context.colors.statOrange;
    case RouteVisitStatus.notReached:
      return context.colors.statusNotReached;
  }
}
