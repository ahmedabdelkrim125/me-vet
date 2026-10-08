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
