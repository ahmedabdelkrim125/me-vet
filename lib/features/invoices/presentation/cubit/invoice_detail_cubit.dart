import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_account/data/repositories/payment_breakdown_repository.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_state.dart';
import 'package:mivet_app/features/rep_session/data/rep_session_store.dart';

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final String invoiceCode;
  final String customerName;
  final double previousBalanceAtView;
  final InvoicesRepository _invoicesRepository;
  final PaymentBreakdownRepository _paymentBreakdownRepository;
  final RepSessionStore _repSessionStore;

  InvoiceDetailCubit({
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
    InvoicesRepository? invoicesRepository,
    PaymentBreakdownRepository? paymentBreakdownRepository,
    RepSessionStore? repSessionStore,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _paymentBreakdownRepository =
            paymentBreakdownRepository ?? PaymentBreakdownRepository.instance,
        _repSessionStore = repSessionStore ?? RepSessionStore.instance,
        super(const InvoiceDetailState());

  Future<void> load() async {
    try {
      final detail =
          await _invoicesRepository.getInvoiceDetailByCode(invoiceCode);
      if (isClosed) return;
      emit(state.copyWith(status: InvoiceDetailStatus.loaded, detail: detail));
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

  Future<void> collectPayment({
    required double amount,
    required PaymentMethod method,
  }) async {
    final detail = state.detail;
    if (detail == null) return;
    try {
      await _invoicesRepository.collectAgainstInvoice(
        invoiceId: detail.id,
        amount: amount,
        method: method,
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return;
    }
    if (!isClosed) await reload();
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
    final detail = state.detail;
    if (detail == null) return null;
    final previousBalance = await _resolvePreviousBalance(detail.id);
    final invoiceRemaining = detail.remaining < 0 ? 0.0 : detail.remaining;
    final accountRemaining = previousBalance + invoiceRemaining;
    final creatorName = detail.creatorName?.trim();
    final repName = (creatorName != null && creatorName.isNotEmpty)
        ? '$creatorName${detail.isFromAdmin ? ' (إدارة)' : ''}'
        : await _resolveRepName(fallbackRepName);
    return InvoicePdfData(
      invoiceNumber: detail.code,
      date: detail.date,
      customerName: customerName,
      repName: repName,
      items: detail.items
          .map((item) => InvoicePdfLineItem(
                name: item.productName,
                quantity: item.quantity,
                price: item.unitPrice,
                total: item.lineTotal,
              ))
          .toList(),
      invoiceTotal: detail.totalAmount,
      discountAmount: _discountOf(detail),
      previousBalance: previousBalance,
      totalDue: detail.totalAmount + previousBalance,
      paidNow: detail.paidNow,
      remaining: accountRemaining < 0 ? 0 : accountRemaining,
      oldDebtCollected: state.oldDebtLines
          .map((line) => InvoicePdfOldDebtLine(
                invoiceCode: line.invoiceCode ?? 'رصيد سابق',
                amount: line.amount,
              ))
          .toList(),
    );
  }

  Future<double> _resolvePreviousBalance(String invoiceId) async {
    try {
      final balance =
          await _invoicesRepository.getBalanceBeforeInvoice(invoiceId);
      return balance ?? previousBalanceAtView;
    } catch (_) {
      return previousBalanceAtView;
    }
  }

  Future<String> _resolveRepName(String? fallbackRepName) async {
    final activeRep = await _repSessionStore.getActiveRep();
    final activeRepName = activeRep?.name.trim();
    if (activeRepName != null && activeRepName.isNotEmpty) return activeRepName;
    final fallback = fallbackRepName?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '';
  }

  double _discountOf(InvoiceFullDetail detail) {
    final fromSubtotal = detail.subtotal - detail.totalAmount;
    return detail.discountAmount > fromSubtotal
        ? detail.discountAmount
        : (fromSubtotal > 0 ? fromSubtotal : 0.0);
  }
}