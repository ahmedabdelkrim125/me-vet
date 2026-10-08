String formatMoney(double value) {
  final negative = value < 0;
  final whole = value.abs().truncate();
  final decimals = (value.abs() - whole);
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  var out = buffer.toString();
  if (decimals > 0.005) {
    out += '.${(decimals * 100).round().toString().padLeft(2, '0')}';
  }
  return '${negative ? '-' : ''}$out ج.م';
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();
}
