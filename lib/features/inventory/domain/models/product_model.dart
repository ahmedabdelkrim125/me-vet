const Object _unset = Object();

class ProductModel {
  final String id;
  final String name;
  final String? imagePath;

  /// Database codes referencing product_categories.code and product_units.code.
  final String category;
  final String unit;
  final double retailPrice;
  final double wholesalePrice;
  final int minStockThreshold;
  final DateTime? expiryDate;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.imagePath,
    required this.category,
    required this.unit,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.minStockThreshold,
    this.expiryDate,
    required this.createdAt,
  });

  double get basePrice => retailPrice;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['image_path'] as String?,
      category: map['category'] as String,
      unit: map['unit'] as String,
      retailPrice: (map['retail_price'] as num).toDouble(),
      wholesalePrice: (map['wholesale_price'] as num).toDouble(),
      minStockThreshold: (map['min_stock_threshold'] as num).toInt(),
      expiryDate: map['expiry_date'] == null
          ? null
          : DateTime.parse(map['expiry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry => expiryDate?.difference(DateTime.now()).inDays;

  ProductModel copyWith({
    String? name,
    Object? imagePath = _unset,
    String? category,
    String? unit,
    double? retailPrice,
    double? wholesalePrice,
    int? minStockThreshold,
    Object? expiryDate = _unset,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      expiryDate:
          expiryDate == _unset ? this.expiryDate : expiryDate as DateTime?,
      createdAt: createdAt,
    );
  }
}
