import 'package:mivet_app/features/customer_account/data/repositories/customer_account_repository.dart';

import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../domain/entities/customer_ledger.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sales_return.dart';
import '../../domain/entities/collection_receipt.dart';
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
    final results = await Future.wait<dynamic>([
      _remote.getCustomerLedger(
        customerId: customerId,
        from: from,
        to: to,
      ),
      _remote.getCustomerCurrentBalance(
        customerId: customerId,
      ),
    ]);

    final rows = results[0] as List<dynamic>;
    final currentBalance = results[1] as double?;

    return CustomerLedgerModel.fromSupabaseRows(
      customerId,
      rows,
      currentBalance: currentBalance,
    );
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
  Future<CollectionReceipt> recordAccountPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final collectionRow = await _remote.recordCustomerAccountPayment(
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    final repId = collectionRow['rep_id'] as String?;
    final collectedAtRaw = collectionRow['collected_at'] as String?;
    final code = collectionRow['code'] as String?;
    final rawAmount = collectionRow['amount'];
    final rawPaymentMethod = collectionRow['payment_method'] as String?;

    if (repId == null || collectedAtRaw == null) {
      throw const CollectionReceiptBuildFailure(
        'بيانات الإيصال غير مكتملة',
      );
    }

    final collectedAt = DateTime.tryParse(collectedAtRaw);

    if (collectedAt == null) {
      throw const CollectionReceiptBuildFailure(
        'بيانات الإيصال غير مكتملة',
      );
    }

    final resolvedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse('$rawAmount') ?? amount;

    final resolvedPaymentMethod =
        paymentMethodFromBackend(rawPaymentMethod) ?? paymentMethod;

    final results = await Future.wait<dynamic>([
      _remote.getCustomerCurrentBalance(customerId: customerId),
      _remote.getRepresentativeName(repId: repId),
    ]);

    final balance = results[0] as double?;
    final representativeName = results[1] as String?;

    if (balance == null || representativeName == null) {
      throw const CollectionReceiptBuildFailure(
        'تعذر جلب بيانات الإيصال بعد نجاح التحصيل',
      );
    }

    return CollectionReceipt(
      customerName: customerName,
      representativeName: representativeName,
      amount: resolvedAmount,
      balanceAfterCollection: balance,
      paymentMethod: resolvedPaymentMethod,
      collectedAt: collectedAt,
      notes: notes,
      collectionCode: code,
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
  Future<Map<String, int>> getReturnedQuantities({
    required String invoiceId,
  }) async {
    return _remote.getReturnedQuantities(
      invoiceId: invoiceId,
    );
  }
}
