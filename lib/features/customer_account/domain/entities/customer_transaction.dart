enum CustomerTransactionType { invoice, payment, salesReturn, refund, adjustment }

extension CustomerTransactionTypeLabel on CustomerTransactionType {
  String get label {
    switch (this) {
      case CustomerTransactionType.invoice:
        return 'فاتورة';
      case CustomerTransactionType.payment:
        return 'تحصيل';
      case CustomerTransactionType.salesReturn:
        return 'مرتجع مبيعات';
      case CustomerTransactionType.refund:
        return 'رد مبلغ';
      case CustomerTransactionType.adjustment:
        return 'تسوية';
    }
  }
}

/// Maps the `customer_transaction_type` Postgres enum to its Dart counterpart.
/// Falls back to [CustomerTransactionType.adjustment] for any unrecognized
/// value instead of throwing, since debit/credit/balance_after still render
/// correctly even if the type label itself is generic.
CustomerTransactionType customerTransactionTypeFromDb(String? value) {
  switch (value) {
    case 'invoice':
      return CustomerTransactionType.invoice;
    case 'payment':
      return CustomerTransactionType.payment;
    case 'sales_return':
      return CustomerTransactionType.salesReturn;
    case 'refund':
      return CustomerTransactionType.refund;
    case 'adjustment':
    default:
      return CustomerTransactionType.adjustment;
  }
}

/// A single row from `get_customer_ledger`. `balanceAfter` is the backend's
/// authoritative running balance — Flutter never recomputes it.
class CustomerTransaction {
  final String id;
  final String customerId;
  final String? repId;
  final CustomerTransactionType type;
  final String? referenceId;
  final String? referenceCode;
  final double debit;
  final double credit;
  final double balanceAfter;
  final DateTime occurredAt;
  final String? notes;

  const CustomerTransaction({
    required this.id,
    required this.customerId,
    this.repId,
    required this.type,
    this.referenceId,
    this.referenceCode,
    required this.debit,
    required this.credit,
    required this.balanceAfter,
    required this.occurredAt,
    this.notes,
  });
}