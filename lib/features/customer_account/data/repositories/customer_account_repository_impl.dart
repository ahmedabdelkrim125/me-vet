// import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
// import '../../domain/entities/customer_ledger.dart';
// import '../../domain/entities/sales_return.dart';
// import '../../domain/repositories/customer_account_repository.dart';
// import '../datasources/customer_account_remote_data_source.dart';
// import '../models/customer_ledger_model.dart';

// class CustomerAccountRepositoryImpl implements CustomerAccountRepository {
//   const CustomerAccountRepositoryImpl(this._remote);

//   final CustomerAccountRemoteDataSource _remote;

//   @override
//   Future<CustomerLedger> getLedger({
//     required String customerId,
//     DateTime? from,
//     DateTime? to,
//   }) async {
//     final rows = await _remote.getCustomerLedger(
//       customerId: customerId,
//       from: from,
//       to: to,
//     );
//     return CustomerLedgerModel.fromSupabaseRows(customerId, rows);
//   }

//   @override
//   Future<void> recordPayment({
//     required String customerId,
//     required double amount,
//     String? invoiceId,
//     required CollectionSource source,
//     String? notes,
//   }) async {
//     await _remote.recordCustomerPayment(
//       customerId: customerId,
//       amount: amount,
//       invoiceId: invoiceId,
//       source: source.dbValue,
//       notes: notes,
//     );
//   }

//   @override
//   Future<void> createSalesReturn({
//     required String customerId,
//     required String invoiceId,
//     required List<SalesReturnItemInput> items,
//     required String reason,
//     String? notes,
//   }) async {
//     await _remote.createSalesReturn(
//       customerId: customerId,
//       invoiceId: invoiceId,
//       items: items.map((item) => item.toRpcJson()).toList(),
//       reason: reason,
//       notes: notes,
//     );
//   }
// }
import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../domain/entities/customer_ledger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sales_return.dart';
import '../../domain/repositories/customer_account_repository.dart';
import '../datasources/customer_account_remote_data_source.dart';
import '../models/customer_ledger_model.dart';

class CustomerAccountRepositoryImpl implements CustomerAccountRepository {
  const CustomerAccountRepositoryImpl(this._remote);

  final CustomerAccountRemoteDataSource _remote;

  @override
  Future<CustomerLedger> getLedger({
    required String customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _remote.getCustomerLedger(
      customerId: customerId,
      from: from,
      to: to,
    );
    return CustomerLedgerModel.fromSupabaseRows(customerId, rows);
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? invoiceId,
    required CollectionSource source,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    await _remote.recordCustomerPaymentV2(
      customerId: customerId,
      amount: amount,
      invoiceId: invoiceId,
      source: source.dbValue,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  @override
  Future<void> createSalesReturn({
    required String customerId,
    required String invoiceId,
    required List<SalesReturnItemInput> items,
    required String reason,
    String? notes,
  }) async {
    await _remote.createSalesReturn(
      customerId: customerId,
      invoiceId: invoiceId,
      items: items.map((item) => item.toRpcJson()).toList(),
      reason: reason,
      notes: notes,
    );
  }

  @override
  Future<Map<String, int>> getReturnedQuantities(
      {required String invoiceId}) async {
    return _remote.getReturnedQuantities(invoiceId: invoiceId);
  }
}
