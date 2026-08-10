import 'product_category.dart';
import 'product_unit.dart';

class ProductModel {
  final String id;
  final String name;
  final String? imagePath;
  final ProductCategory category;
  final ProductUnit unit;
  final double basePrice;
  final int minStockThreshold;

  const ProductModel({
    required this.id,
    required this.name,
    this.imagePath,
    required this.category,
    required this.unit,
    required this.basePrice,
    required this.minStockThreshold,
  });
}
