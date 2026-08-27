String phoneToSyntheticEmail(String phone) {
  final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return '$digitsOnly@mivet.app';
}
