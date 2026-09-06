import '../repositories/customer_account_repository.dart';

class GetInvoiceReturnedQuantities {
  const GetInvoiceReturnedQuantities(this._repository);

  final CustomerAccountRepository _repository;

  Future<Map<String, int>> call({required String invoiceId}) {
    return _repository.getReturnedQuantities(invoiceId: invoiceId);
  }
}
