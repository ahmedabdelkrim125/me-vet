class PaymentBreakdownLine {
  final double amount;

  final bool isOwnInvoice;

  final String? invoiceCode;

  const PaymentBreakdownLine({
    required this.amount,
    required this.isOwnInvoice,
    this.invoiceCode,
  });

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

class PaymentBreakdown {
  final String groupId;

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

  String? get ownInvoiceCode {
    for (final l in lines) {
      if (l.isOwnInvoice && l.invoiceCode != null) return l.invoiceCode;
    }
    return null;
  }

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
