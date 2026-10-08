import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_state.dart';

typedef VehicleStockPickerData = ({
  List<ProductModel> products,
  Map<String, int> quantities,
});

class EditInvoiceCubit extends Cubit<EditInvoiceState> {
  final InvoiceFullDetail invoice;
  final String customerId;
  final InvoicesRepository _invoicesRepository;
  final VehicleStockCubit _vehicleStockCubit;
  final InvoiceDraft _draft = InvoiceDraft();

  final TextEditingController discountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  EditInvoiceCubit({
    required this.invoice,
    required this.customerId,
    InvoicesRepository? invoicesRepository,
    VehicleStockCubit? vehicleStockCubit,
  })  : _invoicesRepository = invoicesRepository ?? InvoicesRepository.instance,
        _vehicleStockCubit = vehicleStockCubit ?? sl<VehicleStockCubit>(),
        super(EditInvoiceState(
          discountAmount: double.tryParse(
                invoice.discountAmount.toStringAsFixed(2),
              ) ??
              0,
        )) {
    discountController.text = invoice.discountAmount.toStringAsFixed(2);
    notesController.text = invoice.notes ?? '';
  }

  Future<void> load() async {
    try {
      final prices = await _invoicesRepository.getCustomerProductPrices(customerId);
      for (final item in invoice.items) {
        _draft.items.add(
          InvoiceItemDraft(
            invoiceItemId: item.id,
            product: _productFromInvoiceItem(item),
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            previousCustomerPrice:
                item.productId == null ? null : prices[item.productId]?.lastPrice,
          ),
        );
      }
      if (isClosed) return;
      emit(state.copyWith(
        loading: false,
        customerPrices: prices,
        items: List.of(_draft.items),
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: error));
    }
  }

  ProductModel _productFromInvoiceItem(InvoiceItemRow item) {
    return ProductModel(
      id: item.productId ?? '',
      name: item.productName,
      category: 'other',
      retailPrice: item.unitPrice,
      wholesalePrice: item.unitPrice,
      minStockThreshold: 0,
      createdAt: invoice.date,
    );
  }

  void changeDiscount(String value) {
    emit(state.copyWith(discountAmount: double.tryParse(value) ?? 0));
  }

  void changePage(int page) => emit(state.copyWith(currentPage: page));

  void increaseQuantity(InvoiceItemDraft item) => setQuantity(item, item.quantity + 1);

  void decreaseQuantity(InvoiceItemDraft item) => setQuantity(item, item.quantity - 1);

  void setQuantity(InvoiceItemDraft item, int value) {
    if (value < 1) return;
    item.quantity = value;
    emit(state.copyWith(items: List.of(_draft.items)));
  }

  void setPrice(InvoiceItemDraft item, double value) {
    item.unitPrice = value;
    emit(state.copyWith(items: List.of(_draft.items)));
  }

  void removeItem(InvoiceItemDraft item) {
    _draft.remove(item);
    final page = state.currentPage > _draft.pageCount
        ? _draft.pageCount
        : state.currentPage;
    emit(state.copyWith(items: List.of(_draft.items), currentPage: page));
  }

  void addProduct(ProductModel product) {
    final index = _draft.items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      _draft.items[index].quantity++;
      emit(state.copyWith(items: List.of(_draft.items)));
      return;
    }
    final prices = state.customerPrices;
    _draft.items.add(
      InvoiceItemDraft(
        product: product,
        productId: product.id,
        quantity: 1,
        unitPrice: suggestedPrice(product, prices),
        previousCustomerPrice: prices[product.id]?.lastPrice,
      ),
    );
    emit(state.copyWith(
      items: List.of(_draft.items),
      currentPage: _draft.pageCount,
    ));
  }

  Future<VehicleStockPickerData?> loadVehicleStockForPicker(String? myId) async {
    try {
      await _vehicleStockCubit.loadVehicles();
      if (myId != null) {
        final mine = _vehicleStockCubit.state.vehicles
            .where((vehicle) => vehicle.repId == myId)
            .toList();
        if (mine.isNotEmpty &&
            mine.first.id != _vehicleStockCubit.state.selectedVehicleId) {
          await _vehicleStockCubit.selectVehicle(mine.first.id);
        }
      }
      final stockState = _vehicleStockCubit.state;
      if (stockState.status == VehicleStockStatus.error ||
          stockState.selectedVehicleId == null) {
        throw Exception(stockState.errorMessage ?? 'تعذر تحميل مخزون العربية');
      }
      final quantities = <String, int>{};
      final products = <ProductModel>[];
      for (final stock in stockState.vehicleStock) {
        final quantity = stock.quantity > 0 ? stock.quantity : 0;
        quantities[stock.productId] = quantity;
        final product = stock.product;
        if (quantity > 0 && product != null && !product.isDeleted) {
          products.add(product);
        }
      }
      products.sort((a, b) => a.name.compareTo(b.name));
      return (products: products, quantities: quantities);
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error));
      return null;
    }
  }

  bool validateForSave() {
    if (state.items.isEmpty) {
      emit(state.copyWith(
        error: 'لا يمكن حفظ الفاتورة بدون أصناف، أضف منتجاً واحداً على الأقل',
      ));
      return false;
    }
    if (state.discountAmount < 0 || state.discountAmount > state.subtotal) {
      emit(state.copyWith(error: 'قيمة الخصم غير صحيحة أو أكبر من الإجمالي'));
      return false;
    }
    return true;
  }

  Future<void> save(String reason) async {
    emit(state.copyWith(saving: true));
    final notes = notesController.text.trim();
    try {
      await _invoicesRepository.editInvoice(
        invoiceId: invoice.id,
        items: _draft.items,
        discountAmount: state.discountAmount,
        reason: reason,
        notes: notes.isEmpty ? null : notes,
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: error));
    }
  }

  @override
  Future<void> close() {
    discountController.dispose();
    notesController.dispose();
    return super.close();
  }
}
