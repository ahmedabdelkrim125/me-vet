import '../../domain/entities/customer_ledger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sales_return.dart';
import '../../domain/entities/collection_receipt.dart';
import '../../../customer-visits/customers/domain/models/collection_record_model.dart';

abstract class CustomerAccountRepository {
  Future<CustomerLedger> getLedger({
    required String customerId,
    DateTime? from,
    DateTime? to,
  });

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? invoiceId,
    required CollectionSource source,
    required PaymentMethod paymentMethod,
    String? notes,
  });

  Future<CollectionReceipt> recordAccountPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  });

  /// Same as [recordAccountPayment] but splits the collected amount across
  /// more than one payment method within a single collection operation.
  Future<CollectionReceipt> recordAccountPaymentSplit({
    required String customerId,
    required String customerName,
    required List<PaymentSplitEntry> payments,
    String? notes,
  });

  Future<void> createSalesReturn({
    required String customerId,
    required String invoiceId,
    required List<SalesReturnItemInput> items,
    required String reason,
    String? notes,
  });

  Future<Map<String, int>> getReturnedQuantities({required String invoiceId});
}
