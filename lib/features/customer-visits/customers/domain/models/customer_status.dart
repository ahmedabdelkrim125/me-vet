///
/// TODO(auto-status): المفروض ده يبقى محسوب أوتوماتيك من سلوك العميل

enum CustomerStatus { active, needsFollowUp, stopped }

extension CustomerStatusX on CustomerStatus {
  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'نشط';
      case CustomerStatus.needsFollowUp:
        return 'يحتاج متابعة';
      case CustomerStatus.stopped:
        return 'متوقف';
    }
  }

  /// القيمة المطابقة لـ enum `customer_status` في Supabase (snake_case).
  String get dbValue {
    switch (this) {
      case CustomerStatus.active:
        return 'active';
      case CustomerStatus.needsFollowUp:
        return 'needs_follow_up';
      case CustomerStatus.stopped:
        return 'stopped';
    }
  }
}

CustomerStatus customerStatusFromDb(String? value) {
  switch (value) {
    case 'active':
      return CustomerStatus.active;
    case 'stopped':
      return CustomerStatus.stopped;
    default:
      return CustomerStatus.needsFollowUp;
  }
}
