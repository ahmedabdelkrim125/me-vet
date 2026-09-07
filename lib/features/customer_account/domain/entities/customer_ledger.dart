import 'customer_transaction.dart';

class CustomerLedger {
  final String customerId;
  final List<CustomerTransaction> transactions;
  final double? currentBalance;

  const CustomerLedger({
    required this.customerId,
    required this.transactions,
    this.currentBalance,
  });
}