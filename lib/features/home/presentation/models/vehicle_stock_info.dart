import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';

class VehicleStockInfo {
  final bool known;
  final Map<String, int> quantities;
  final List<ProductModel> products;
  final String? errorMessage;

  const VehicleStockInfo({
    required this.known,
    required this.quantities,
    this.products = const [],
    this.errorMessage,
  });

  factory VehicleStockInfo.fromState(VehicleStockState state) {
    final known = state.selectedVehicleId != null &&
        (state.status == VehicleStockStatus.loaded ||
            state.status == VehicleStockStatus.success ||
            state.status == VehicleStockStatus.loadingAction);

    if (!known) {
      return VehicleStockInfo(
        known: false,
        quantities: const {},
        errorMessage: state.status == VehicleStockStatus.error
            ? state.errorMessage
            : null,
      );
    }

    final quantities = <String, int>{};
    final products = <ProductModel>[];
    for (final stock in state.vehicleStock) {
      final quantity = stock.quantity > 0 ? stock.quantity : 0;
      quantities[stock.productId] = quantity;
      final product = stock.product;
      if (quantity > 0 && product != null && !product.isDeleted) {
        products.add(product);
      }
    }
    return VehicleStockInfo(
      known: true,
      quantities: quantities,
      products: products,
    );
  }

  int availableFor(String productId) => quantities[productId] ?? 0;
}
