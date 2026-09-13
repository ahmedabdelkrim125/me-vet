import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';

import '../../domain/entities/sales_return.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/collection_receipt.dart';
import '../../domain/usecases/create_sales_return.dart';
import '../../domain/usecases/get_customer_ledger.dart';
import '../../domain/usecases/record_customer_account_payment.dart';
import '../../domain/usecases/get_invoice_returned_quantities.dart';
import 'customer_account_state.dart';

class CustomerAccountCubit extends Cubit<CustomerAccountState> {
  CustomerAccountCubit({
    required GetCustomerLedger getCustomerLedger,
    required RecordCustomerAccountPayment recordCustomerAccountPayment,
    required CreateSalesReturn createSalesReturn,
    required GetInvoiceReturnedQuantities getInvoiceReturnedQuantities,
  })  : _getCustomerLedger = getCustomerLedger,
        _recordCustomerAccountPayment = recordCustomerAccountPayment,
        _createSalesReturn = createSalesReturn,
        _getInvoiceReturnedQuantities = getInvoiceReturnedQuantities,
        super(const CustomerAccountState(customerId: '', customerName: ''));

  final GetCustomerLedger _getCustomerLedger;
  final RecordCustomerAccountPayment _recordCustomerAccountPayment;
  final CreateSalesReturn _createSalesReturn;
  final GetInvoiceReturnedQuantities _getInvoiceReturnedQuantities;

  Future<void> init({
    required String customerId,
    required String customerName,
    double? fallbackBalance,
  }) async {
    emit(CustomerAccountState(
      customerId: customerId,
      customerName: customerName,
      fallbackBalance: fallbackBalance,
      isLoading: true,
    ));
    await _loadLedger();
  }

  Future<void> refresh() => _loadLedger();

  Future<void> _loadLedger() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearLedgerError: true));
    try {
      final ledger = await _getCustomerLedger(customerId: state.customerId);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, ledger: ledger));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        ledgerError: mapErrorToAppException(e),
      ));
    }
  }

  Future<void> fetchReturnedQuantities(String invoiceId) async {
    try {
      final quantities =
          await _getInvoiceReturnedQuantities(invoiceId: invoiceId);
      if (isClosed) return;
      emit(state.copyWith(returnedQuantities: quantities));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(actionError: mapErrorToAppException(e)));
      rethrow;
    }
  }

  Future<void> recordPayment({
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    emit(state.copyWith(actionStatus: CustomerAccountActionStatus.submitting));
    try {
      final receipt = await _recordCustomerAccountPayment(
        customerId: state.customerId,
        customerName: state.customerName,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.success,
        actionSuccessMessage: 'تم تسجيل التحصيل بنجاح',
        receipt: receipt,
      ));
      await _loadLedger();
    } on CollectionReceiptBuildFailure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.success,
        actionSuccessMessage: 'تم تسجيل التحصيل بنجاح',
        receiptError: AppException(e.message),
      ));
      await _loadLedger();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.failure,
        actionError: mapErrorToAppException(e),
      ));
    }
  }

  Future<void> submitSalesReturn({
    required String invoiceId,
    required List<SalesReturnItemInput> items,
    required String reason,
    String? notes,
  }) async {
    emit(state.copyWith(actionStatus: CustomerAccountActionStatus.submitting));
    try {
      await _createSalesReturn(
        customerId: state.customerId,
        invoiceId: invoiceId,
        items: items,
        reason: reason,
        notes: notes,
      );
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.success,
        actionSuccessMessage: 'تم تسجيل مرتجع المبيعات بنجاح',
      ));
      await _loadLedger();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.failure,
        actionError: mapErrorToAppException(e),
      ));
    }
  }

  void acknowledgeAction() {
    emit(state.copyWith(
      actionStatus: CustomerAccountActionStatus.idle,
      clearActionError: true,
      clearActionSuccess: true,
    ));
  }

  void acknowledgeLedgerError() {
    emit(state.copyWith(clearLedgerError: true));
  }

  void acknowledgeReceipt() {
    emit(state.copyWith(clearReceipt: true, clearReceiptError: true));
  }
}
