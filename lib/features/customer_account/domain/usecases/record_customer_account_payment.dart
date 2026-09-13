import 'package:mivet_app/core/errors/app_exception.dart';

import '../../data/repositories/customer_account_repository.dart';
import '../entities/collection_receipt.dart';
import '../entities/payment_method.dart';

class RecordCustomerAccountPayment {
  const RecordCustomerAccountPayment(this._repository);

  final CustomerAccountRepository _repository;

  Future<CollectionReceipt> call({
    required String customerId,
    required String customerName,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) {
    if (amount <= 0) {
      throw const AppException('المبلغ المحصّل لازم يكون أكبر من صفر');
    }
    return _repository.recordAccountPayment(
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }
}
