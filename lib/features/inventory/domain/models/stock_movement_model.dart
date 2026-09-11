class StockMovementModel {
  final String id;
  final String productId;
  final String? productName; // Added to hold domain mapping
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
    this.productName,
    this.vehicleId,
    required this.type,
    required this.quantity,
    this.createdBy,
    required this.createdAt,
    this.referenceId,
    this.note,
  });

  String get arabicTypeLabel {
    switch (type) {
      case 'loaded_to_vehicle':
        return 'إضافة إلى مخزن السيارة';
      case 'deducted_from_vehicle':
        return 'خصم من مخزن السيارة (فاتورة)';
      case 'returned_to_vehicle':
        return 'مرتجع إلى مخزن السيارة';
      default:
        return 'حركة مخزون: $type';
    }
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    String? pName;
    if (map['products'] != null && map['products'] is Map) {
      pName = map['products']['name'] as String?;
    }
    
    return StockMovementModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: pName,
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