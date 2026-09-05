import '../entities/customer_ledger.dart';
import '../repositories/customer_account_repository.dart';

class GetCustomerLedger {
  const GetCustomerLedger(this._repository);

  final CustomerAccountRepository _repository;

  Future<CustomerLedger> call({
    required String customerId,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getLedger(customerId: customerId, from: from, to: to);
  }
}