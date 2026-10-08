import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_record_model.dart';

const List<String> arabicMonths = [
  '',
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

class StatementEntry {
  final InvoiceRecordModel? invoice;
  final PaymentBreakdown? payment;

  const StatementEntry.invoice(InvoiceRecordModel this.invoice) : payment = null;
  const StatementEntry.payment(PaymentBreakdown this.payment) : invoice = null;

  DateTime get date => invoice?.date ?? payment!.collectedAt;
}

Map<String, List<StatementEntry>> groupStatementByMonth(
  List<InvoiceRecordModel> invoices,
  List<PaymentBreakdown> payments,
) {
  final entries = <StatementEntry>[
    for (final invoice in invoices) StatementEntry.invoice(invoice),
    for (final payment in payments) StatementEntry.payment(payment),
  ]..sort((a, b) => b.date.compareTo(a.date));

  final groups = <String, List<StatementEntry>>{};
  for (final entry in entries) {
    final date = entry.date.toLocal();
    final key = '${arabicMonths[date.month]} ${date.year}';
    groups.putIfAbsent(key, () => []).add(entry);
  }
  return groups;
}
