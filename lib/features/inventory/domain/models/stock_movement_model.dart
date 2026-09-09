class StockMovementModel {
  final String id;
  final String productId;
  final String? vehicleId;
  final String type;
  final int quantity;
  final String? createdBy;
  final DateTime createdAt;
  final String? referenceId;
  final String? note;

  const StockMovementModel({
    required this.id,
    required this.productId,
    this.vehicleId,
    required this.type,
    required this.quantity,
    this.createdBy,
    required this.createdAt,
    this.referenceId,
    this.note,
  });

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      vehicleId: map['vehicle_id'] as String?,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      referenceId: map['reference_id'] as String?,
      note: map['note'] as String?,
    );
  }
}
