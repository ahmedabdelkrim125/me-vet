/// حالة العميل، بتتحدد يدويًا دلوقتي من المندوب/الأونر.
///
/// TODO(auto-status): المفروض ده يبقى محسوب أوتوماتيك من سلوك العميل
/// (تاريخ آخر زيارة، تاريخ آخر فاتورة، انتظام الشراء...) بدل الاختيار
/// اليدوي. محتاج نصمم "قاعدة" واضحة الأول (مثلاً: عدّاه 45 يوم من غير
/// فاتورة/زيارة = "متوقف"، عدّاه 20 يوم = "يحتاج متابعة"، غير كده "نشط")
/// ونطبقها كـ computed field أو trigger في Supabase وقت فيتشر الفواتير/
/// الزيارات، مش قبل كده لأن مفيش بيانات حقيقية كفاية نبني عليها الحساب.
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
