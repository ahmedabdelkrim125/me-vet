import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/invoices/data/invoice_pdf_data_service.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_state.dart';

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final String invoiceCode;
  final String customerName;
  final double previousBalanceAtView;
  final InvoicesRepository _invoicesRepository;
  final InvoicePdfDataService _pdfDataService;

  InvoiceDetailCubit({
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
    InvoicesRepository? invoicesRepository,
    InvoicePdfDataService? pdfDataService,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _pdfDataService = pdfDataService ?? InvoicePdfDataService(),
        super(const InvoiceDetailState());

  Future<void> load() async {
    try {
      final detail =
          await _invoicesRepository.getInvoiceDetailByCode(invoiceCode);
      if (isClosed) return;
      final summary = await _resolveAccountSummary(detail.id);
      if (isClosed) return;
      emit(state.copyWith(
        status: InvoiceDetailStatus.loaded,
        detail: detail,
        accountSummary: summary,
      ));
      unawaited(_loadLaterCollections(detail.id));
      unawaited(_loadApplicableCredit(detail));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: InvoiceDetailStatus.failure));
    }
  }

  Future<void> reload() async {
    emit(state.copyWith(status: InvoiceDetailStatus.loading));
    await load();
  }

  Future<void> _loadApplicableCredit(InvoiceFullDetail detail) async {
    if (detail.remaining <= 0) {
      if (!isClosed) emit(state.copyWith(applicableCredit: 0));
      return;
    }
    try {
      final credit =
          await _invoicesRepository.getInvoiceApplicableCredit(detail.id);
      if (isClosed) return;
      emit(state.copyWith(applicableCredit: credit));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(applicableCredit: 0));
    }
  }

  Future<void> _loadLaterCollections(String invoiceId) async {
    try {
      final total =
          await _invoicesRepository.getLaterCollectionsTotal(invoiceId);
      if (isClosed) return;
      emit(state.copyWith(laterCollections: total));
    } catch (_) {}
  }

  double get paidWithInvoice {
    final detail = state.detail;
    if (detail == null) return 0;
    final paid = state.accountSummary?.totalPaid ?? detail.paidNow;
    return double.parse(paid.toStringAsFixed(2));
  }

  Future<void> setPaidAmount({
    required double newPaid,
    required PaymentMethod method,
  }) async {
    final detail = state.detail;
    if (detail == null) return;
    if ((newPaid - paidWithInvoice).abs() < 0.005) return;
    try {
      await _invoicesRepository.setInvoicePaidAmount(
        invoiceId: detail.id,
        newPaid: newPaid,
        method: method,
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(successMessage: 'تم تعديل المبلغ المدفوع'));
    await reload();
  }

  Future<void> applyCredit(double amount) async {
    final detail = state.detail;
    if (detail == null) return;
    try {
      await _invoicesRepository.applyCustomerCreditToInvoice(
        invoiceId: detail.id,
        amount: amount,
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(successMessage: 'تم سداد الفاتورة من رصيد العميل'));
    await reload();
  }

  Future<InvoicePdfData?> buildInvoiceData({String? fallbackRepName}) async {
    if (state.detail == null) return null;
    return _pdfDataService.buildByCode(
      invoiceCode: invoiceCode,
      customerName: customerName,
      fallbackRepName: fallbackRepName,
      fallbackPreviousBalance: previousBalanceAtView,
    );
  }

  Future<InvoiceAccountSummary?> _resolveAccountSummary(
    String invoiceId,
  ) async {
    try {
      return await _invoicesRepository.getInvoiceAccountSummary(invoiceId);
    } catch (_) {
      return null;
    }
  }
}
