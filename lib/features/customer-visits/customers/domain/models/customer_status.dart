enum CustomerStatus { active, needsFollowUp, stalled }

extension CustomerStatusX on CustomerStatus {
  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'نشط';
      case CustomerStatus.needsFollowUp:
        return 'يحتاج متابعة';
      case CustomerStatus.stalled:
        return 'متوقف';
    }
  }
}
