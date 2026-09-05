import '../../domain/entities/customer_transaction.dart';

/// Parses one row of `get_customer_ledger`'s result set. Model extends the
/// entity so a `List<CustomerTransactionModel>` can be used wherever
/// `List<CustomerTransaction>` is expected, with no separate mapping step.
class CustomerTransactionModel extends CustomerTransaction {
  const CustomerTransactionModel({
    required super.id,
    required super.customerId,
    super.repId,
    required super.type,
    super.referenceId,
    super.referenceCode,
    required super.debit,
    required super.credit,
    required super.balanceAfter,
    required super.occurredAt,
    super.notes,
  });

  factory CustomerTransactionModel.fromSupabaseRow(Map<String, dynamic> row) {
    return CustomerTransactionModel(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      repId: row['rep_id'] as String?,
      type: customerTransactionTypeFromDb(row['transaction_type'] as String?),
      referenceId: row['reference_id'] as String?,
      referenceCode: row['reference_code'] as String?,
      debit: (row['debit'] as num?)?.toDouble() ?? 0,
      credit: (row['credit'] as num?)?.toDouble() ?? 0,
      balanceAfter: (row['balance_after'] as num).toDouble(),
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      notes: row['notes'] as String?,
    );
  }
}