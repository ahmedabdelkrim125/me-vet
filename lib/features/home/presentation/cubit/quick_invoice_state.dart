import 'dart:math';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/models/payment_split_row.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';

enum IssueReadiness { rejected, needsConfirmation, ready }

class QuickInvoiceState {
  static const int pageSize = 15;

  final String invoiceNumber;
  final DateTime invoiceDate;
  final InvoiceCustomerModel? customer;
  final List<InvoiceLineItemModel> lineItems;
  final Map<String, CustomerProductPrice> customerPrices;
  final int currentPage;
  final bool loadingCustomerPrices;
  final bool isIssuing;
  final PaymentMethod? paymentMethod;
  final bool splitPaymentMethods;
  final List<PaymentSplitRow> paymentSplitRows;
  final double discountAmount;
  final double paidNow;
  final String? message;
  final Object? error;
  final IssuedInvoiceInfo? issued;

  const QuickInvoiceState({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.paymentSplitRows,
    this.customer,
    this.lineItems = const [],
    this.customerPrices = const {},
    this.currentPage = 1,
    this.loadingCustomerPrices = false,
    this.isIssuing = false,
    this.paymentMethod,
    this.splitPaymentMethods = false,
    this.discountAmount = 0,
    this.paidNow = 0,
    this.message,
    this.error,
    this.issued,
  });

  factory QuickInvoiceState.initial({InvoiceCustomerModel? customer}) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    return QuickInvoiceState(
      invoiceNumber: 'INV-${date.year}-${100 + Random().nextInt(900)}',
      invoiceDate: date,
      customer: customer,
      paymentSplitRows: [PaymentSplitRow(), PaymentSplitRow()],
    );
  }

  double get subtotal =>
      lineItems.fold<double>(0, (sum, item) => sum + item.total);
  double get grandTotal => subtotal - discountAmount;
  double get previousBalance => customer?.customer.currentBalance ?? 0;
  double get totalDue => previousBalance + grandTotal;
  double get payableDue => totalDue > 0 ? totalDue : 0;
  double get creditUsed =>
      previousBalance < 0 ? min(-previousBalance, grandTotal) : 0;
  double get remainingBalance {
    final value = totalDue - paidNow;
    return value < 0 ? 0 : value;
  }

  double get paymentSplitTotal =>
      paymentSplitRows.fold<double>(0, (sum, row) => sum + row.amount);

  bool get canIssue => customer != null && lineItems.isNotEmpty && !isIssuing;

  QuickInvoiceState copyWith({
    DateTime? invoiceDate,
    InvoiceCustomerModel? customer,
    List<InvoiceLineItemModel>? lineItems,
    Map<String, CustomerProductPrice>? customerPrices,
    int? currentPage,
    bool? loadingCustomerPrices,
    bool? isIssuing,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    bool? splitPaymentMethods,
    List<PaymentSplitRow>? paymentSplitRows,
    double? discountAmount,
    double? paidNow,
    String? message,
    Object? error,
    IssuedInvoiceInfo? issued,
  }) {
    return QuickInvoiceState(
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customer: customer ?? this.customer,
      lineItems: lineItems ?? this.lineItems,
      customerPrices: customerPrices ?? this.customerPrices,
      currentPage: currentPage ?? this.currentPage,
      loadingCustomerPrices:
          loadingCustomerPrices ?? this.loadingCustomerPrices,
      isIssuing: isIssuing ?? this.isIssuing,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      splitPaymentMethods: splitPaymentMethods ?? this.splitPaymentMethods,
      paymentSplitRows: paymentSplitRows ?? this.paymentSplitRows,
      discountAmount: discountAmount ?? this.discountAmount,
      paidNow: paidNow ?? this.paidNow,
      message: message,
      error: error,
      issued: issued,
    );
  }
}
