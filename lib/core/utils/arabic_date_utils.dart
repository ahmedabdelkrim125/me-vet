/// Shared Arabic date formatting helpers.
///
/// Keeping this in one place means the home header, the rep-entry live
/// clock, and anywhere else that shows "today" all agree on the same
/// weekday/month names and greeting logic.
library;

const List<String> arabicWeekdays = [
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// e.g. "صباح الخير" / "مساء الخير" based on the current hour.
String arabicGreeting([DateTime? at]) {
  final now = at ?? DateTime.now();
  return now.hour < 12 ? 'صباح الخير' : 'مساء الخير';
}

/// e.g. "الأحد، 6 أغسطس"
String arabicDateLabel([DateTime? at]) {
  final now = at ?? DateTime.now();
  final weekday = arabicWeekdays[now.weekday - 1];
  final month = arabicMonths[now.month - 1];
  return '$weekday، ${now.day} $month';
}

/// e.g. "14:05:30"
String time24Label([DateTime? at]) {
  final now = at ?? DateTime.now();
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
