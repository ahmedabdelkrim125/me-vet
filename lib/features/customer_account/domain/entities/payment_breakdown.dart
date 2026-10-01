/// One line of a payment: how much of the money went where.
class PaymentBreakdownLine {
  final double amount;

  /// `true` when the line paid the invoice that was issued together with the
  /// payment (`new_invoice_payment`), `false` when it collected an older debt
  /// (`old_debt_payment`).
  final bool isOwnInvoice;

  /// Code of the invoice this line was applied to. `null` when the money was
  /// not matched to any invoice (an old balance without an invoice).
  final String? invoiceCode;

  const PaymentBreakdownLine({
    required this.amount,
    required this.isOwnInvoice,
    this.invoiceCode,
  });

  /// Parses the rows of `get_invoice_payment_breakdown` (one invoice's own
  /// payment group, no `group_id`/`payment_code`/`collected_at` columns).
  static List<PaymentBreakdownLine> listFromRows(List<dynamic> rows) {
    return [
      for (final raw in rows)
        PaymentBreakdownLine(
          amount: ((raw as Map<String, dynamic>)['amount'] as num).toDouble(),
          isOwnInvoice: raw['source'] == 'new_invoice_payment',
          invoiceCode: raw['invoice_code'] as String?,
        ),
    ];
  }
}

/// A whole payment (one `split_group_id`): the total the customer paid, and
/// the lines it was split into. Built from `get_customer_payment_breakdown`.
class PaymentBreakdown {
  final String groupId;

  /// Base code of the payment (`PAY-2026-000349`). Matches the `referenceCode`
  /// of the payment row in the customer ledger.
  final String code;
  final DateTime collectedAt;
  final List<PaymentBreakdownLine> lines;

  const PaymentBreakdown({
    required this.groupId,
    required this.code,
    required this.collectedAt,
    required this.lines,
  });

  double get total => lines.fold(0.0, (sum, l) => sum + l.amount);

  List<PaymentBreakdownLine> get ownInvoiceLines =>
      lines.where((l) => l.isOwnInvoice).toList();

  List<PaymentBreakdownLine> get oldDebtLines =>
      lines.where((l) => !l.isOwnInvoice).toList();

  /// Code of the invoice issued together with this payment, if any.
  String? get ownInvoiceCode {
    for (final l in lines) {
      if (l.isOwnInvoice && l.invoiceCode != null) return l.invoiceCode;
    }
    return null;
  }

  /// Groups the flat rows of `get_customer_payment_breakdown` by payment.
  /// Keeps the order of the rows (newest payment first).
  static List<PaymentBreakdown> fromRows(List<dynamic> rows) {
    final order = <String>[];
    final byGroup = <String, List<Map<String, dynamic>>>{};
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      final key = row['group_id'] as String;
      if (!byGroup.containsKey(key)) order.add(key);
      byGroup.putIfAbsent(key, () => []).add(row);
    }

    return [
      for (final key in order)
        PaymentBreakdown(
          groupId: key,
          code: (byGroup[key]!.first['payment_code'] as String?) ?? '',
          collectedAt:
              DateTime.parse(byGroup[key]!.first['collected_at'] as String),
          lines: [
            for (final row in byGroup[key]!)
              PaymentBreakdownLine(
                amount: (row['amount'] as num).toDouble(),
                isOwnInvoice: row['source'] == 'new_invoice_payment',
                invoiceCode: row['invoice_code'] as String?,
              ),
          ],
        ),
    ];
  }
}
