import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_account/data/repositories/payment_breakdown_repository.dart';
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
  final PaymentBreakdownRepository _paymentBreakdownRepository;
  final InvoicePdfDataService _pdfDataService;

  InvoiceDetailCubit({
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
    InvoicesRepository? invoicesRepository,
    PaymentBreakdownRepository? paymentBreakdownRepository,
    InvoicePdfDataService? pdfDataService,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _paymentBreakdownRepository =
            paymentBreakdownRepository ?? PaymentBreakdownRepository.instance,
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
      unawaited(_loadOldDebt(detail.id));
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

  Future<void> _loadOldDebt(String invoiceId) async {
    try {
      final lines = await _paymentBreakdownRepository.getForInvoice(invoiceId);
      if (isClosed) return;
      emit(state.copyWith(
        oldDebtLines: lines.where((line) => !line.isOwnInvoice).toList(),
      ));
    } catch (_) {}
  }

  Future<void> setPaidAmount({
    required double newPaid,
    required PaymentMethod method,
  }) async {
    final detail = state.detail;
    if (detail == null) return;
    final delta = double.parse((newPaid - detail.paidNow).toStringAsFixed(2));
    if (delta == 0) return;
    try {
      if (delta > 0) {
        await _invoicesRepository.collectAgainstInvoice(
          invoiceId: detail.id,
          amount: delta,
          method: method,
        );
      } else {
        await _invoicesRepository.releaseInvoiceOverpayment(
          invoiceId: detail.id,
          newPaid: newPaid,
        );
      }
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

  Future<void> releaseOverpayment(double newPaid) async {
    final detail = state.detail;
    if (detail == null) return;
    try {
      await _invoicesRepository.releaseInvoiceOverpayment(
        invoiceId: detail.id,
        newPaid: newPaid,
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(successMessage: 'تم تعديل المبلغ المدفوع'));
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
