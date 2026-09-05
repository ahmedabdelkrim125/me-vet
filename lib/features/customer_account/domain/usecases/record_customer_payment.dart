import 'package:mivet_app/core/errors/app_exception.dart';
import '../repositories/customer_account_repository.dart';

class RecordCustomerPayment {
  const RecordCustomerPayment(this._repository);

  final CustomerAccountRepository _repository;

  Future<void> call({
    required String customerId,
    required double amount,
    String? invoiceId,
    required CollectionSource source,
    String? notes,
  }) {
    if (amount <= 0) {
      throw const AppException('المبلغ المحصّل لازم يكون أكبر من صفر');
    }
    return _repository.recordPayment(
      customerId: customerId,
      amount: amount,
      invoiceId: invoiceId,
      source: source,
      notes: notes,
    );
  }
}