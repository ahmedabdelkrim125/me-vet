import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/inventory/data/products_repository.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_line_input.dart';
import 'package:mivet_app/features/owner_dashboard/data/admin_actions_service.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_state.dart';

class HistoricalInvoiceCubit extends Cubit<HistoricalInvoiceState> {
  final String customerId;
  final ProductsRepository _productsRepository;
  final AdminActionsService _adminActionsService;

  final TextEditingController discountController =
      TextEditingController(text: '0');
  final TextEditingController paidNowController =
      TextEditingController(text: '0');
  final TextEditingController notesController = TextEditingController();

  HistoricalInvoiceCubit({
    required this.customerId,
    ProductsRepository? productsRepository,
    AdminActionsService? adminActionsService,
  })  : _productsRepository = productsRepository ?? ProductsRepository.instance,
        _adminActionsService = adminActionsService ?? AdminActionsService(),
        super(HistoricalInvoiceState(invoiceDate: DateTime.now()));

  Future<void> loadCatalog() async {
    try {
      final products = await _productsRepository.getProducts();
      if (isClosed) return;
      emit(state.copyWith(loadingCatalog: false, catalog: products));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loadingCatalog: false, error: error));
    }
  }

  void setInvoiceDate(DateTime date) => emit(state.copyWith(invoiceDate: date));

  void setCashSale(bool value) => emit(state.copyWith(isCashSale: value));

  void setPaymentMethod(PaymentMethod method) =>
      emit(state.copyWith(paymentMethod: method));

  void changeDiscount(String value) {
    emit(state.copyWith(discountAmount: double.tryParse(value.trim()) ?? 0));
  }

  void changePaidNow(String value) {
    emit(state.copyWith(paidNow: double.tryParse(value.trim()) ?? 0));
  }

  void incrementExisting(ProductModel product) {
    final lines = List<HistoricalInvoiceLine>.of(state.lines);
    final index = lines.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    emit(state.copyWith(lines: lines));
  }

  bool hasProduct(ProductModel product) =>
      state.lines.any((line) => line.product.id == product.id);

  void addLine(ProductModel product, int quantity, double unitPrice) {
    emit(state.copyWith(
      lines: [
        ...state.lines,
        HistoricalInvoiceLine(
          product: product,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      ],
    ));
  }

  void updateLine(HistoricalInvoiceLine line, int quantity, double unitPrice) {
    final lines = List<HistoricalInvoiceLine>.of(state.lines);
    final index = lines.indexOf(line);
    if (index == -1) return;
    lines[index] = line.copyWith(quantity: quantity, unitPrice: unitPrice);
    emit(state.copyWith(lines: lines));
  }

  void removeLine(HistoricalInvoiceLine line) {
    emit(state.copyWith(lines: List.of(state.lines)..remove(line)));
  }

  Future<void> submit() async {
    final validation = _validate();
    if (validation != null) {
      emit(state.copyWith(info: validation));
      return;
    }
    emit(state.copyWith(submitting: true));
    final notes = notesController.text.trim();
    try {
      await _adminActionsService.issueHistoricalInvoice(
        customerId: customerId,
        items: state.lines
            .map((line) => InvoiceLineInput(
                  productId: line.product.id,
                  productName: line.product.name,
                  unitPrice: line.unitPrice,
                  quantity: line.quantity,
                ))
            .toList(),
        invoiceDate: state.invoiceDate,
        discountAmount: state.discountAmount,
        isCashSale: state.isCashSale,
        paidNow: state.paidNow,
        paymentMethod: state.paymentMethod,
        notes: notes.isEmpty ? null : notes,
      );
      if (isClosed) return;
      emit(state.copyWith(
        submitting: false,
        info: 'اتسجلت الفاتورة التاريخية بنجاح',
        submitted: true,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: error));
    }
  }

  String? _validate() {
    if (state.lines.isEmpty) return 'ضيف صنف واحد على الأقل قبل الحفظ';
    if (state.discountAmount < 0) return 'قيمة الخصم غير صحيحة';
    if (state.discountAmount > state.subtotal) {
      return 'قيمة الخصم أكبر من إجمالي الفاتورة';
    }
    if (state.paidNow > state.total) return 'المدفوع أكبر من إجمالي الفاتورة';
    return null;
  }

  @override
  Future<void> close() {
    discountController.dispose();
    paidNowController.dispose();
    notesController.dispose();
    return super.close();
  }
}
