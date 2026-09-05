import 'package:mivet_app/core/errors/app_exception.dart';

import '../entities/sales_return.dart';
import '../repositories/customer_account_repository.dart';

class CreateSalesReturn {
  const CreateSalesReturn(this._repository);

  final CustomerAccountRepository _repository;

  Future<void> call({
    required String customerId,
    required String invoiceId,
    required List<SalesReturnItemInput> items,
    required String reason,
    String? notes,
  }) {
    if (items.isEmpty) {
      throw const AppException('لازم تختار صنف واحد على الأقل عشان ترجّعه');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw const AppException('الكمية المرتجعة لازم تكون أكبر من صفر');
    }
    return _repository.createSalesReturn(
      customerId: customerId,
      invoiceId: invoiceId,
      items: items,
      reason: reason,
      notes: notes,
    );
  }
}