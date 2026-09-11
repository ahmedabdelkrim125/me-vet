import 'product_catalog_item.dart';

class ProductCatalog {
  final List<ProductCatalogItem> categories;
  final List<ProductCatalogItem> units;

  const ProductCatalog({
    this.categories = const [],
    this.units = const [],
  });

  static const empty = ProductCatalog();

  String categoryName(String code) => _nameFor(categories, code);

  String unitName(String code) => _nameFor(units, code);

  String _nameFor(List<ProductCatalogItem> items, String code) {
    for (final item in items) {
      if (item.code == code) return item.name;
    }
    return code;
  }

  ProductCatalog copyWith({
    List<ProductCatalogItem>? categories,
    List<ProductCatalogItem>? units,
  }) {
    return ProductCatalog(
      categories: categories ?? this.categories,
      units: units ?? this.units,
    );
  }
}