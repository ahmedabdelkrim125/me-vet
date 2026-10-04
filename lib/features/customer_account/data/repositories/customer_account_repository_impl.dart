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

    // الوقت بييجي UTC من Supabase (timestamptz)؛ لازم يتحول للتوقيت المحلي
    // عشان يطابق وقت التحصيل الفعلي في إيصال التحصيل.
    final collectedAt = DateTime.tryParse(collectedAtRaw)?.toLocal();

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
  Future<CollectionReceipt> recordAccountPaymentSplit({
    required String customerId,
    required String customerName,
    required List<PaymentSplitEntry> payments,
    String? notes,
  }) async {
    final summary = await _remote.recordCustomerAccountPaymentSplit(
      customerId: customerId,
      payments: payments,
      notes: notes,
    );

    final repId = summary['rep_id'] as String?;
    final collectedAtRaw = summary['collected_at'] as String?;
    final code = summary['code'] as String?;
    final rawTotal = summary['total_amount'];
    final rawPayments = summary['payments'];

    if (repId == null || collectedAtRaw == null) {
      throw const CollectionReceiptBuildFailure('بيانات الإيصال غير مكتملة');
    }

    // الوقت بييجي UTC من Supabase (timestamptz)؛ لازم يتحول للتوقيت المحلي
    // عشان يطابق وقت التحصيل الفعلي في إيصال التحصيل.
    final collectedAt = DateTime.tryParse(collectedAtRaw)?.toLocal();
    if (collectedAt == null) {
      throw const CollectionReceiptBuildFailure('بيانات الإيصال غير مكتملة');
    }

    final totalAmount = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse('$rawTotal') ??
            payments.fold<double>(0, (sum, p) => sum + p.amount);

    final breakdown = (rawPayments as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((row) {
      final method = paymentMethodFromBackend(
            row['payment_method'] as String?,
          ) ??
          payments.first.method;
      final amount = row['amount'] is num
          ? (row['amount'] as num).toDouble()
          : double.tryParse('${row['amount']}') ?? 0;
      return PaymentSplitEntry(method: method, amount: amount);
    }).toList();

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
      amount: totalAmount,
      balanceAfterCollection: balance,
      paymentMethod:
          breakdown.isNotEmpty ? breakdown.first.method : payments.first.method,
      collectedAt: collectedAt,
      notes: notes,
      collectionCode: code,
      paymentBreakdown: breakdown.isNotEmpty ? breakdown : null,
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
