// import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
// import '../entities/customer_ledger.dart';
// import '../entities/sales_return.dart';

// /// Contract for the customer-account feature's data access. Implemented by
// /// [CustomerAccountRepositoryImpl] in the data layer; this file has no
// /// Supabase dependency.
// abstract class CustomerAccountRepository {
//   Future<CustomerLedger> getLedger({
//     required String customerId,
//     DateTime? from,
//     DateTime? to,
//   });

//   Future<void> recordPayment({
//     required String customerId,
//     required double amount,
//     String? invoiceId,
//     required CollectionSource source,
//     String? notes,
//   });

//   Future<void> createSalesReturn({
//     required String customerId,
//     required String invoiceId,
//     required List<SalesReturnItemInput> items,
//     required String reason,
//     String? notes,
//   });
// }
import '../../domain/entities/customer_ledger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sales_return.dart';
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

  Future<void> recordAccountPayment({
    required String customerId,
    required double amount,
    required PaymentMethod paymentMethod,
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
