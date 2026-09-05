import '../../domain/entities/customer_ledger.dart';
import 'customer_transaction_model.dart';

class CustomerLedgerModel extends CustomerLedger {
  CustomerLedgerModel({
    required super.customerId,
    required super.transactions,
  });

  factory CustomerLedgerModel.fromSupabaseRows(
    String customerId,
    List<dynamic> rows,
  ) {
    final transactions = rows
        .map((row) =>
            CustomerTransactionModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
    return CustomerLedgerModel(customerId: customerId, transactions: transactions);
  }
}