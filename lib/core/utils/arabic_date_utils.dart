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

String arabicGreeting([DateTime? at]) {
  final now = at ?? DateTime.now();
  return now.hour < 12 ? 'صباح الخير' : 'مساء الخير';
}

String arabicDateLabel([DateTime? at]) {
  final now = at ?? DateTime.now();
  final weekday = arabicWeekdays[now.weekday - 1];
  final month = arabicMonths[now.month - 1];
  return '$weekday، ${now.day} $month';
}

String time24Label([DateTime? at]) {
  final now = at ?? DateTime.now();
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
