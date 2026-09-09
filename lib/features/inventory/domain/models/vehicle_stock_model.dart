import 'product_model.dart';

class VehicleStockModel {
  final String vehicleId;
  final String productId;
  final int quantity;
  final int minThreshold;
  final ProductModel? product;

  const VehicleStockModel({
    required this.vehicleId,
    required this.productId,
    required this.quantity,
    required this.minThreshold,
    this.product,
  });

  bool get isLowStock => quantity <= minThreshold;

  factory VehicleStockModel.fromMap(Map<String, dynamic> map) {
    final productMap = map['products'];

    return VehicleStockModel(
      vehicleId: map['vehicle_id'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toInt(),
      minThreshold: (map['min_threshold'] as num).toInt(),
      product: productMap is Map<String, dynamic>
          ? ProductModel.fromMap(productMap)
          : productMap is Map
              ? ProductModel.fromMap(
                  Map<String, dynamic>.from(productMap),
                )
              : null,
    );
  }
}
