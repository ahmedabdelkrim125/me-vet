enum StockAdjustmentType { returned, damaged }

extension StockAdjustmentTypeX on StockAdjustmentType {
  String get label => this == StockAdjustmentType.returned ? 'مرتجع' : 'هالك';
}

/// A single returns/damage write-off event, valued at the product's
/// price at the time it was recorded.
class StockAdjustmentModel {
  final String id;
  final String productId;
  final String productName;
  final StockAdjustmentType type;
  final int quantity;
  final double value;
  final DateTime createdAt;
  final String? note;

  const StockAdjustmentModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.value,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'type': type.name,
        'quantity': quantity,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
      };

  factory StockAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      type:
          StockAdjustmentType.values.firstWhere((t) => t.name == json['type']),
      quantity: json['quantity'] as int,
      value: (json['value'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}
