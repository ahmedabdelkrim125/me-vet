enum NotificationType {
  visitReminder,
  customerStalled,
  creditLimitWarning,
  creditLimitExceeded,
  mainStockLow,
  vehicleStockLow,
  productExpiringSoon,
  productExpired,
  dailyReportReminder,
}

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.visitReminder:
        return 'تذكير بزيارة';
      case NotificationType.customerStalled:
        return 'عميل متوقف';
      case NotificationType.creditLimitWarning:
        return 'اقتراب من حد الائتمان';
      case NotificationType.creditLimitExceeded:
        return 'تخطي حد الائتمان';
      case NotificationType.mainStockLow:
        return 'مخزون منخفض';
      case NotificationType.vehicleStockLow:
        return 'مخزون العربية منخفض';
      case NotificationType.productExpiringSoon:
        return 'صلاحية قربت تخلص';
      case NotificationType.productExpired:
        return 'صنف منتهي الصلاحية';
      case NotificationType.dailyReportReminder:
        return 'تذكير بتقرير اليوم';
    }
  }

  /// القيمة المطابقة لـ enum `notification_type` في Supabase (snake_case).
  String get dbValue {
    switch (this) {
      case NotificationType.visitReminder:
        return 'visit_reminder';
      case NotificationType.customerStalled:
        return 'customer_stalled';
      case NotificationType.creditLimitWarning:
        return 'credit_limit_warning';
      case NotificationType.creditLimitExceeded:
        return 'credit_limit_exceeded';
      case NotificationType.mainStockLow:
        return 'main_stock_low';
      case NotificationType.vehicleStockLow:
        return 'vehicle_stock_low';
      case NotificationType.productExpiringSoon:
        return 'product_expiring_soon';
      case NotificationType.productExpired:
        return 'product_expired';
      case NotificationType.dailyReportReminder:
        return 'daily_report_reminder';
    }
  }
}

NotificationType notificationTypeFromDb(String? value) {
  switch (value) {
    case 'visit_reminder':
      return NotificationType.visitReminder;
    case 'customer_stalled':
      return NotificationType.customerStalled;
    case 'credit_limit_warning':
      return NotificationType.creditLimitWarning;
    case 'credit_limit_exceeded':
      return NotificationType.creditLimitExceeded;
    case 'main_stock_low':
      return NotificationType.mainStockLow;
    case 'vehicle_stock_low':
      return NotificationType.vehicleStockLow;
    case 'product_expiring_soon':
      return NotificationType.productExpiringSoon;
    case 'product_expired':
      return NotificationType.productExpired;
    case 'daily_report_reminder':
    default:
      return NotificationType.dailyReportReminder;
  }
}
