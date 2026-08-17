import 'stock_movement_type.dart';

class StockMovementModel {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'type': type.name,
        'quantity': quantity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      type: StockMovementType.values.firstWhere((t) => t.name == json['type']),
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}