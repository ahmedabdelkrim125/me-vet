class VehicleStockAddedTodayModel {
  final String productName;
  final String category;
  final int quantityAdded;
  final int currentQuantity;
  final DateTime addedAt;

  const VehicleStockAddedTodayModel({
    required this.productName,
    required this.category,
    required this.quantityAdded,
    required this.currentQuantity,
    required this.addedAt,
  });

  factory VehicleStockAddedTodayModel.fromMap(Map<String, dynamic> map) {
    return VehicleStockAddedTodayModel(
      productName: (map['product_name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      quantityAdded: (map['quantity_added'] as num?)?.toInt() ?? 0,
      currentQuantity: (map['current_quantity'] as num?)?.toInt() ?? 0,
      addedAt: map['added_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['added_at'] as String).toLocal(),
    );
  }
}