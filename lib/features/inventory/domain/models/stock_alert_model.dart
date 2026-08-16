enum StockAlertLevel { mainWarehouse, vehicle }

class StockAlertModel {
  final String productId;
  final String productName;
  final StockAlertLevel level;
  final int currentQuantity;
  final int threshold;

  const StockAlertModel({
    required this.productId,
    required this.productName,
    required this.level,
    required this.currentQuantity,
    required this.threshold,
  });
}
