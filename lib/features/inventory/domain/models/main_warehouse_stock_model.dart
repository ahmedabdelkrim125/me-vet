class MainWarehouseStockModel {
  final String productId;
  final int quantity;

  const MainWarehouseStockModel({
    required this.productId,
    required this.quantity,
  });

  MainWarehouseStockModel copyWith({int? quantity}) {
    return MainWarehouseStockModel(
      productId: productId,
      quantity: quantity ?? this.quantity,
    );
  }
}