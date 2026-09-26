final RegExp _bidiControlChars = RegExp(r'[\u200B-\u200F\u202A-\u202E\uFEFF]');

String sanitizeReportText(String text) =>
    text.replaceAll(_bidiControlChars, '');

String formatReportDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

String formatReportTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
