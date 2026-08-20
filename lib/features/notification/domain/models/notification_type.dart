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
}
