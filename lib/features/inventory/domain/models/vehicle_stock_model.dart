class VehicleStockModel {
  final String productId;
  final int quantity;
  final int minThreshold;

  const VehicleStockModel({
    required this.productId,
    required this.quantity,
    required this.minThreshold,
  });

  VehicleStockModel copyWith({int? quantity, int? minThreshold}) {
    return VehicleStockModel(
      productId: productId,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
    );
  }
}
