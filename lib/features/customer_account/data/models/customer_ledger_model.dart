// import '../../domain/entities/customer_ledger.dart';
// import '../../domain/entities/customer_transaction.dart';
// import 'customer_transaction_model.dart';

// class CustomerLedgerModel extends CustomerLedger {
//   CustomerLedgerModel({
//     required super.customerId,
//     required super.transactions,
//   });

//   factory CustomerLedgerModel.fromSupabaseRows(
//     String customerId,
//     List<dynamic> rows,
//   ) {
//     final List<CustomerTransaction> transactions = rows
//         .map<CustomerTransaction>((row) =>
//             CustomerTransactionModel.fromSupabaseRow(
//                 row as Map<String, dynamic>))
//         .toList();
//     return CustomerLedgerModel(
//         customerId: customerId, transactions: transactions);
//   }
// }
import '../../domain/entities/customer_ledger.dart';
import '../../domain/entities/customer_transaction.dart';
import 'customer_transaction_model.dart';

class CustomerLedgerModel extends CustomerLedger {
  const CustomerLedgerModel({
    required super.customerId,
    required super.transactions,
    required super.currentBalance,
  });

  factory CustomerLedgerModel.fromSupabaseRows(
    String customerId,
    List<dynamic> rows, {
    double? currentBalance,
  }) {
    final transactions = rows
        .map<CustomerTransaction>(
          (row) => CustomerTransactionModel.fromSupabaseRow(
            row as Map<String, dynamic>,
          ),
        )
        .toList();

    return CustomerLedgerModel(
      customerId: customerId,
      transactions: transactions,
      currentBalance: currentBalance,
    );
  }
}
