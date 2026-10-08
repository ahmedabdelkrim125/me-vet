import 'product_catalog_item.dart';

class ProductCatalog {
  final List<ProductCatalogItem> categories;

  const ProductCatalog({
    this.categories = const [],
  });

  static const empty = ProductCatalog();

  String categoryName(String code) => _nameFor(categories, code);

  String _nameFor(List<ProductCatalogItem> items, String code) {
    for (final item in items) {
      if (item.code == code) return item.name;
    }
    return code;
  }

  ProductCatalog copyWith({
    List<ProductCatalogItem>? categories,
  }) {
    return ProductCatalog(
      categories: categories ?? this.categories,
    );
  }
}
