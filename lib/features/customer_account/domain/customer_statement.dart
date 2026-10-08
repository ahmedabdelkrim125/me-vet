import 'package:mivet_app/core/utils/months_before.dart';

import 'entities/customer_ledger.dart';
import 'entities/customer_transaction.dart';

class CustomerStatement {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double openingBalance;
  final double closingBalance;
  final double totalDebit;
  final double totalCredit;

  final List<CustomerTransaction> transactions;

  const CustomerStatement({
    required this.periodStart,
    required this.periodEnd,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.transactions,
  });

  factory CustomerStatement.lastMonths(
    CustomerLedger ledger, {
    int months = 6,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = monthsBefore(end, months);

    final inPeriodNewestFirst = <CustomerTransaction>[];
    CustomerTransaction? newestBeforePeriod;
    for (final t in ledger.transactions) {
      if (t.occurredAt.toLocal().isBefore(start)) {
        newestBeforePeriod ??= t;
      } else {
        inPeriodNewestFirst.add(t);
      }
    }

    final chronological = inPeriodNewestFirst.reversed.toList();

    final double opening;
    if (newestBeforePeriod != null) {
      opening = newestBeforePeriod.balanceAfter;
    } else if (chronological.isNotEmpty) {
      final first = chronological.first;
      opening = first.balanceAfter - first.debit + first.credit;
    } else {
      opening = ledger.currentBalance ?? 0;
    }

    final closing = ledger.currentBalance ??
        (chronological.isNotEmpty ? chronological.last.balanceAfter : opening);

    return CustomerStatement(
      periodStart: start,
      periodEnd: end,
      openingBalance: opening,
      closingBalance: closing,
      totalDebit: chronological.fold(0.0, (sum, t) => sum + t.debit),
      totalCredit: chronological.fold(0.0, (sum, t) => sum + t.credit),
      transactions: chronological,
    );
  }
}
