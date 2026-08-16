import 'product_category.dart';
import 'product_unit.dart';

const Object _unset = Object();

class ProductModel {
  final String id;
  final String name;
  final String? imagePath;
  final ProductCategory category;
  final ProductUnit unit;
  final double basePrice;
  final int minStockThreshold;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.imagePath,
    required this.category,
    required this.unit,
    required this.basePrice,
    required this.minStockThreshold,
    required this.createdAt,
  });

  ProductModel copyWith({
    String? name,
    Object? imagePath = _unset,
    ProductCategory? category,
    ProductUnit? unit,
    double? basePrice,
    int? minStockThreshold,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      createdAt: createdAt,
    );
  }
}
