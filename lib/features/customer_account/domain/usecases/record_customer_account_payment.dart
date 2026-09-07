import 'package:mivet_app/core/errors/app_exception.dart';

import '../entities/payment_method.dart';
import '../repositories/customer_account_repository.dart';

class RecordCustomerAccountPayment {
  const RecordCustomerAccountPayment(this._repository);

  final CustomerAccountRepository _repository;

  Future<void> call({
    required String customerId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) {
    if (amount <= 0) {
      throw const AppException('المبلغ المحصّل لازم يكون أكبر من صفر');
    }
    return _repository.recordAccountPayment(
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }
}
