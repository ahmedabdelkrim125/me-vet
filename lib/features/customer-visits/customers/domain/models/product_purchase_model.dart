class ProductPurchaseModel {
  final String name;
  final double customerPrice;
  final DateTime lastPurchaseDate;

  const ProductPurchaseModel({
    required this.name,
    required this.customerPrice,
    required this.lastPurchaseDate,
  });
}
