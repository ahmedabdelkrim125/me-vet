import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_visits/customers/data/customers_repository.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_line_input.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/models/payment_split_row.dart';
import 'package:mivet_app/features/home/presentation/models/product_picker_args.dart';
import 'package:mivet_app/features/home/presentation/models/vehicle_stock_info.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_mappers.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';

class QuickInvoiceCubit extends Cubit<QuickInvoiceState> {
  static const String _noExtraStockMessage =
      'لا يوجد مخزون إضافي متاح لهذا المنتج في العربية';

  final VehicleStockCubit _vehicleStockCubit;
  final CustomersRepository _customersRepository;
  final InvoicesRepository _invoicesRepository;

  final TextEditingController discountController =
      TextEditingController(text: '0');
  final TextEditingController notesController = TextEditingController();
  final TextEditingController paidNowController =
      TextEditingController(text: '0');

  int _customerPricesRequestId = 0;

  QuickInvoiceCubit({
    required VehicleStockCubit vehicleStockCubit,
    InvoiceCustomerModel? initialCustomer,
    CustomersRepository? customersRepository,
    InvoicesRepository? invoicesRepository,
  })  : _vehicleStockCubit = vehicleStockCubit,
        _customersRepository =
            customersRepository ?? CustomersRepository.instance,
        _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        super(QuickInvoiceState.initial(customer: initialCustomer));

  void initialize() {
    _customersRepository.initialize();
    final customer = state.customer;
    if (customer != null) loadCustomerPrices(customer.customer.id);
    final stockStatus = _vehicleStockCubit.state.status;
    if (stockStatus != VehicleStockStatus.loading &&
        stockStatus != VehicleStockStatus.loadingStock) {
      _vehicleStockCubit.loadVehicles();
    }
  }

  void setInvoiceDate(DateTime date) => emit(state.copyWith(invoiceDate: date));

  Future<List<InvoiceCustomerModel>?> loadCustomers() async {
    await _customersRepository.initialize();
    if (isClosed) return null;
    return invoiceCustomersFromRepository();
  }

  Future<void> selectCustomer(InvoiceCustomerModel picked) async {
    paidNowController.text = '0';
    emit(state.copyWith(
      customer: picked,
      lineItems: [],
      customerPrices: {},
      currentPage: 1,
      paidNow: 0,
      clearPaymentMethod: true,
    ));
    await loadCustomerPrices(picked.customer.id);
  }

  Future<void> loadCustomerPrices(String customerId) async {
    final requestId = ++_customerPricesRequestId;
    emit(state.copyWith(loadingCustomerPrices: true, customerPrices: {}));
    try {
      final prices =
          await _invoicesRepository.getCustomerProductPrices(customerId);
      if (isClosed || requestId != _customerPricesRequestId) return;
      emit(
          state.copyWith(customerPrices: prices, loadingCustomerPrices: false));
    } catch (error) {
      if (isClosed || requestId != _customerPricesRequestId) return;
      emit(state.copyWith(loadingCustomerPrices: false, error: error));
    }
  }

  void changePage(int page) => emit(state.copyWith(currentPage: page));

  void changePrice(InvoiceLineItemModel item, double price) {
    item.unitPrice = price;
    emit(state.copyWith(lineItems: List.of(state.lineItems)));
  }

  void changeQuantity(InvoiceLineItemModel item, int desiredQuantity) {
    final result = _applyStockGuard(
      stockInfo: VehicleStockInfo.fromState(_vehicleStockCubit.state),
      product: item.product,
      currentQuantity: item.quantity,
      desiredQuantity: desiredQuantity,
    );
    final items = List<InvoiceLineItemModel>.of(state.lineItems);
    var page = state.currentPage;
    if (result.quantity <= 0) {
      items.remove(item);
      page = _clampPage(page, items.length);
    } else {
      item.quantity = result.quantity;
    }
    emit(state.copyWith(
      lineItems: items,
      currentPage: page,
      message: result.message,
    ));
  }

  void removeLineItem(InvoiceLineItemModel item) {
    final items = List<InvoiceLineItemModel>.of(state.lineItems)..remove(item);
    emit(state.copyWith(
      lineItems: items,
      currentPage: _clampPage(state.currentPage, items.length),
    ));
  }

  void replaceLineItems(List<InvoiceLineItemModel> items) {
    emit(state.copyWith(
      lineItems: List.of(items),
      currentPage: _clampPage(state.currentPage, items.length),
    ));
  }

  Future<ProductPickerArgs?> prepareProductPicker() async {
    final stockInfo = VehicleStockInfo.fromState(_vehicleStockCubit.state);
    if (!stockInfo.known) {
      emit(state.copyWith(
        message: stockInfo.errorMessage ??
            'جاري تحميل بيانات مخزون العربية، حاول بعد قليل',
      ));
      return null;
    }
    var waited = 0;
    while (state.loadingCustomerPrices && waited < 40 && !isClosed) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }
    if (isClosed) return null;
    return ProductPickerArgs(
      existing: state.lineItems,
      products: stockInfo.products,
      customerPrices: state.customerPrices,
      stockByProductId: stockInfo.quantities,
    );
  }

  void changeDiscount(String value) {
    emit(state.copyWith(discountAmount: double.tryParse(value.trim()) ?? 0));
  }

  void changePaidNow(String value) {
    emit(state.copyWith(paidNow: double.tryParse(value) ?? 0));
  }

  void toggleSplitPayment() {
    emit(state.copyWith(splitPaymentMethods: !state.splitPaymentMethods));
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void selectSplitMethod(int index, PaymentMethod method) {
    state.paymentSplitRows[index].method = method;
    emit(state.copyWith(paymentSplitRows: List.of(state.paymentSplitRows)));
  }

  void changeSplitAmount() {
    emit(state.copyWith(paymentSplitRows: List.of(state.paymentSplitRows)));
  }

  void addSplitRow() {
    emit(state.copyWith(
      paymentSplitRows: [...state.paymentSplitRows, PaymentSplitRow()],
    ));
  }

  void removeSplitRow(int index) {
    final rows = List<PaymentSplitRow>.of(state.paymentSplitRows);
    rows.removeAt(index).dispose();
    emit(state.copyWith(paymentSplitRows: rows));
  }

  IssueReadiness checkIssueReadiness() {
    if (state.customer == null) return _reject('الرجاء اختيار العميل أولاً');
    if (state.lineItems.isEmpty) return _reject('أضف منتجات للفاتورة');
    if (state.discountAmount < 0) return _reject('قيمة الخصم غير صحيحة');
    if (state.discountAmount > state.subtotal) {
      return _reject('قيمة الخصم أكبر من إجمالي الفاتورة');
    }
    final paid = state.paidNow;
    if (paid < 0) return _reject('المبلغ المدفوع غير صحيح');
    if (paid > state.payableDue + 0.01) {
      return _reject('المبلغ المدفوع يتجاوز إجمالي المستحق على العميل');
    }
    if (paid <= 0.005 && state.payableDue > 0.005) {
      return IssueReadiness.needsConfirmation;
    }
    return IssueReadiness.ready;
  }

  Future<void> issueInvoice() async {
    final validationError = _validatePaymentAndLines();
    if (validationError != null) {
      emit(state.copyWith(message: validationError));
      return;
    }
    final snapshot = state;
    final customer = snapshot.customer;
    if (customer == null) return;

    final paid = snapshot.paidNow;
    final total = snapshot.grandTotal;
    final notes = notesController.text.trim();
    final splitEntries = paid > 0 && snapshot.splitPaymentMethods
        ? snapshot.paymentSplitRows
            .where((row) => row.method != null && row.amount > 0)
            .map((row) => PaymentSplitEntry(
                  method: row.method!,
                  amount: row.amount,
                ))
            .toList()
        : null;

    emit(state.copyWith(isIssuing: true));

    try {
      final issued = await _invoicesRepository.issueInvoice(
        customerId: customer.customer.id,
        items: snapshot.lineItems
            .map((item) => InvoiceLineInput(
                  productId: item.product.id,
                  productName: item.product.name,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                ))
            .toList(),
        discountAmount: snapshot.discountAmount,
        isCashSale: false,
        paidNow: paid,
        paymentMethod: paid > 0 && !snapshot.splitPaymentMethods
            ? snapshot.paymentMethod
            : null,
        payments: splitEntries,
        notes: notes.isEmpty ? null : notes,
      );

      if (snapshot.previousBalance < 0) {
        try {
          final applicable =
              await _invoicesRepository.getInvoiceApplicableCredit(issued.id);
          if (applicable > 0.005) {
            await _invoicesRepository.applyCustomerCreditToInvoice(
              invoiceId: issued.id,
              amount: applicable,
            );
          }
        } catch (_) {}
      }

      await _customersRepository.refresh();

      try {
        await _vehicleStockCubit.refresh();
      } catch (_) {}
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isIssuing: false, error: e));
      return;
    }

    if (isClosed) return;

    emit(state.copyWith(
      issued: IssuedInvoiceInfo(
        invoiceNumber: snapshot.invoiceNumber,
        amount: total,
        date: snapshot.invoiceDate,
      ),
    ));
  }

  InvoicePdfData? buildInvoiceData(String repName) {
    final customer = state.customer;
    if (customer == null) {
      emit(state.copyWith(message: 'الرجاء اختيار العميل'));
      return null;
    }
    if (state.lineItems.isEmpty) {
      emit(state.copyWith(message: 'أضف منتجات للفاتورة'));
      return null;
    }
    final snapshot = state;
    return InvoicePdfData(
      invoiceNumber: snapshot.invoiceNumber,
      date: snapshot.invoiceDate,
      customerName: customer.customer.name,
      repName: repName,
      items: snapshot.lineItems
          .map((item) => InvoicePdfLineItem(
                name: item.product.name,
                quantity: item.quantity,
                price: item.unitPrice,
                total: item.total,
              ))
          .toList(),
      invoiceTotal: snapshot.grandTotal,
      discountAmount: snapshot.discountAmount,
      previousBalance: snapshot.previousBalance,
      totalDue: snapshot.totalDue,
      paidNow: snapshot.paidNow,
      remaining: snapshot.remainingBalance,
    );
  }

  IssueReadiness _reject(String message) {
    emit(state.copyWith(message: message));
    return IssueReadiness.rejected;
  }

  String? _validatePaymentAndLines() {
    final paid = state.paidNow;
    if (paid > 0 && !state.splitPaymentMethods && state.paymentMethod == null) {
      return 'اختر طريقة الدفع';
    }
    if (paid > 0 && state.splitPaymentMethods) {
      final validRows = state.paymentSplitRows
          .where((row) => row.method != null && row.amount > 0);
      if (validRows.isEmpty) {
        return 'أدخل طريقة دفع واحدة على الأقل بمبلغها';
      }
      if ((state.paymentSplitTotal - paid).abs() > 0.01) {
        return 'مجموع طرق الدفع لازم يساوي المبلغ المدفوع';
      }
    }
    for (final item in state.lineItems) {
      if (item.product.name.trim().isEmpty ||
          item.quantity <= 0 ||
          item.unitPrice < 0) {
        return 'يرجى التحقق من كمية وسعر جميع المنتجات';
      }
    }
    return null;
  }

  ({int quantity, String? message}) _applyStockGuard({
    required VehicleStockInfo stockInfo,
    required InvoiceProductModel product,
    required int currentQuantity,
    required int desiredQuantity,
  }) {
    if (desiredQuantity <= currentQuantity) {
      return (
        quantity: desiredQuantity < 0 ? 0 : desiredQuantity,
        message: null,
      );
    }
    if (!stockInfo.known) {
      return (
        quantity: currentQuantity,
        message: 'تعذر تعديل الكمية، جاري التأكد من مخزون العربية',
      );
    }
    final available = stockInfo.availableFor(product.id);
    if (available <= currentQuantity) {
      return (quantity: currentQuantity, message: _noExtraStockMessage);
    }
    final clamped = desiredQuantity > available ? available : desiredQuantity;
    return (
      quantity: clamped,
      message: clamped == currentQuantity ? _noExtraStockMessage : null,
    );
  }

  int _clampPage(int page, int itemCount) {
    if (itemCount == 0) return 1;
    return page
        .clamp(1, (itemCount / QuickInvoiceState.pageSize).ceil())
        .toInt();
  }

  @override
  Future<void> close() {
    discountController.dispose();
    notesController.dispose();
    paidNowController.dispose();
    for (final row in state.paymentSplitRows) {
      row.dispose();
    }
    return super.close();
  }
}
