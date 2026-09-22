/// [date] minus [months] calendar months (time of day dropped), clamping the
/// day so 31 Aug - 6 months is 28/29 Feb instead of rolling into March.
DateTime monthsBefore(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) - months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
  return DateTime(year, month, day);
}
