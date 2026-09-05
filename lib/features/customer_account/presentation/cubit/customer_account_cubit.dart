import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';

import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../domain/entities/sales_return.dart';
import '../../domain/usecases/create_sales_return.dart';
import '../../domain/usecases/get_customer_ledger.dart';
import '../../domain/usecases/record_customer_payment.dart';
import 'customer_account_state.dart';

class CustomerAccountCubit extends Cubit<CustomerAccountState> {
  CustomerAccountCubit({
    required GetCustomerLedger getCustomerLedger,
    required RecordCustomerPayment recordCustomerPayment,
    required CreateSalesReturn createSalesReturn,
  })  : _getCustomerLedger = getCustomerLedger,
        _recordCustomerPayment = recordCustomerPayment,
        _createSalesReturn = createSalesReturn,
        super(const CustomerAccountState(customerId: '', customerName: ''));

  final GetCustomerLedger _getCustomerLedger;
  final RecordCustomerPayment _recordCustomerPayment;
  final CreateSalesReturn _createSalesReturn;

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
    emit(state.copyWith(isLoading: true));
    try {
      final ledger = await _getCustomerLedger(customerId: state.customerId);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, ledger: ledger));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, actionError: mapErrorToAppException(e)));
    }
  }

  Future<void> recordPayment({
    required double amount,
    String? invoiceId,
    required CollectionSource source,
    String? notes,
  }) async {
    emit(state.copyWith(actionStatus: CustomerAccountActionStatus.submitting));
    try {
      await _recordCustomerPayment(
        customerId: state.customerId,
        amount: amount,
        invoiceId: invoiceId,
        source: source,
        notes: notes,
      );
      if (isClosed) return;
      emit(state.copyWith(
        actionStatus: CustomerAccountActionStatus.success,
        actionSuccessMessage: 'تم تسجيل التحصيل بنجاح',
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

  /// Resets the one-shot action flags after a BlocListener has already
  /// shown the toast for them, so they don't refire on the next rebuild.
  void acknowledgeAction() {
    emit(state.copyWith(
      actionStatus: CustomerAccountActionStatus.idle,
      clearActionError: true,
      clearActionSuccess: true,
    ));
  }
}