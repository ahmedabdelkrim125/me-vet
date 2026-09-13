/// A catalog record stored in Supabase. [code] is what products persist and
/// [name] is the human-readable Arabic label shown in the application.
class ProductCatalogItem {
  final String code;
  final String name;

  const ProductCatalogItem({required this.code, required this.name});

  factory ProductCatalogItem.fromMap(Map<String, dynamic> map) {
    return ProductCatalogItem(
      code: map['code'] as String,
      name: (map['name'] ?? map['label'] ?? map['code']) as String,
    );
  }
}
