import 'customer_transaction.dart';

class CustomerLedger {
  final String customerId;
  final List<CustomerTransaction> transactions;

  const CustomerLedger({
    required this.customerId,
    required this.transactions,
  });

  /// `balance_after` of the most recent transaction. Null when the customer
  /// has no ledger rows yet.
  double? get currentBalance {
    if (transactions.isEmpty) return null;
    CustomerTransaction latest = transactions.first;
    for (final transaction in transactions.skip(1)) {
      if (transaction.occurredAt.isAfter(latest.occurredAt)) {
        latest = transaction;
      }
    }
    return latest.balanceAfter;
  }
}
