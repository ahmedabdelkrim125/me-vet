import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_state.dart';
import 'package:mivet_app/features/home/presentation/models/product_picker_args.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';

class ProductPickerCubit extends Cubit<ProductPickerState> {
  static const String stockLimitMessage =
      'الكمية المتاحة في العربية أقل من المطلوب';

  ProductPickerCubit(ProductPickerArgs args)
      : super(ProductPickerState.fromArgs(args));

  void search(String query) {
    final words = normalizeArabic(query).split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final visible = words.isEmpty
        ? state.allProducts
        : state.allProducts.where((p) {
            final key = state.searchKeys[p.id] ?? '';
            return words.every(key.contains);
          }).toList();
    emit(state.copyWith(query: query, visibleProducts: visible));
  }

  void setQuantity(InvoiceProductModel product, int quantity) {
    final available = state.availableStockFor(product);
    final clamped =
        quantity < 0 ? 0 : (quantity > available ? available : quantity);
    final cart = List<InvoiceLineItemModel>.of(state.cart);
    final existingIndex = cart.indexWhere((c) => c.product.id == product.id);
    final existingPrice =
        existingIndex == -1 ? null : cart[existingIndex].unitPrice;
    cart.removeWhere((c) => c.product.id == product.id);
    if (clamped > 0) {
      final previous = state.previousPriceFor(product);
      cart.add(InvoiceLineItemModel(
        product: product,
        quantity: clamped,
        unitPrice: existingPrice ?? previous ?? product.price,
        previousCustomerPrice: previous,
      ));
    }
    emit(state.copyWith(
      cart: cart,
      message: clamped < quantity ? stockLimitMessage : null,
    ));
  }

  void notifyStockLimit() => emit(state.copyWith(message: stockLimitMessage));
}
