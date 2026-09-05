import 'customer_transaction.dart';

class CustomerLedger {
  final String customerId;
  final List<CustomerTransaction> transactions;

  const CustomerLedger({
    required this.customerId,
    required this.transactions,
  });

  /// `balance_after` of the most recent transaction (rows arrive ordered
  /// desc by `occurred_at` from `get_customer_ledger`). Null when the
  /// customer has no ledger rows yet — callers should fall back to a
  /// display-only balance in that case, never to zero.
  double? get currentBalance =>
      transactions.isEmpty ? null : transactions.first.balanceAfter;
}