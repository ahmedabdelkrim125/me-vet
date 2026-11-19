import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/features/customer_account/data/repositories/payment_breakdown_repository.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_state.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_record_model.dart';

class CustomerInvoicesCubit extends Cubit<CustomerInvoicesState> {
  final String customerId;
  final InvoicesRepository _invoicesRepository;
  final PaymentBreakdownRepository _paymentBreakdownRepository;

  CustomerInvoicesCubit({
    required this.customerId,
    InvoicesRepository? invoicesRepository,
    PaymentBreakdownRepository? paymentBreakdownRepository,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _paymentBreakdownRepository =
            paymentBreakdownRepository ?? PaymentBreakdownRepository.instance,
        super(const CustomerInvoicesState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final results = await Future.wait([
        _invoicesRepository.getInvoicesForCustomer(customerId),
        _loadPayments(),
        _loadCollectionSources(),
      ]);
      if (isClosed) return;
      emit(state.copyWith(
        loading: false,
        invoices: results[0] as List<InvoiceRecordModel>,
        payments: results[1] as List<PaymentBreakdown>,
        collectionSources: results[2] as Map<String, String?>,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: error));
    }
  }

  void setShowAll(bool value) => emit(state.copyWith(showAll: value));

  Future<bool> editPayment({
    required PaymentBreakdown payment,
    required double newTotal,
    required String reason,
  }) async {
    final collectionId = payment.editableCollectionId;
    if (collectionId == null) {
      emit(state.copyWith(
        error: const AppException('تعذر تحديد التحصيل المطلوب تعديله'),
      ));
      return false;
    }
    try {
      await _paymentBreakdownRepository.editCollectionAmount(
        collectionId: collectionId,
        newTotal: newTotal,
        reason: reason,
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return false;
    }
    if (isClosed) return true;
    await load();
    return true;
  }

  Future<List<PaymentBreakdown>> _loadPayments() async {
    try {
      return await _paymentBreakdownRepository.getForCustomer(customerId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CustomerStatement] breakdown failed: $error');
      }
      return const [];
    }
  }

  Future<Map<String, String?>> _loadCollectionSources() async {
    try {
      return await _paymentBreakdownRepository
          .getCollectionSourcesForCustomer(customerId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CustomerStatement] collection sources failed: $error');
      }
      return const {};
    }
  }
}
