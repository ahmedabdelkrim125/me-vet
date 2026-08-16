import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import '../../domain/models/notification_type.dart';

List<List<dynamic>> notificationTypeIcon(NotificationType type) {
  switch (type) {
    case NotificationType.visitReminder:
      return HugeIcons.strokeRoundedCalendar01;
    case NotificationType.customerStalled:
      return HugeIcons.strokeRoundedAlertDiamond;
    case NotificationType.creditLimitWarning:
      return HugeIcons.strokeRoundedAlert02;
    case NotificationType.creditLimitExceeded:
      return HugeIcons.strokeRoundedAlertCircle;
    case NotificationType.mainStockLow:
      return HugeIcons.strokeRoundedDeliveryBox01;
    case NotificationType.vehicleStockLow:
      return HugeIcons.strokeRoundedDeliveryTruck01;
    case NotificationType.dailyReportReminder:
      return HugeIcons.strokeRoundedDoc01;
  }
}

Color notificationTypeColor(BuildContext context, NotificationType type) {
  switch (type) {
    case NotificationType.visitReminder:
      return context.colors.statBlue;
    case NotificationType.customerStalled:
      return context.colors.statusNotReached;
    case NotificationType.creditLimitWarning:
      return context.colors.statOrange;
    case NotificationType.creditLimitExceeded:
      return context.colors.statusNotReached;
    case NotificationType.mainStockLow:
      return context.colors.statOrange;
    case NotificationType.vehicleStockLow:
      return context.colors.statOrange;
    case NotificationType.dailyReportReminder:
      return context.colors.primary;
  }
}
