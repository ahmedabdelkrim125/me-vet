import 'vehicle_stock_model.dart';

enum StockLevel { all, available, low, out }

extension StockLevelText on StockLevel {
  String get reportTitle {
    switch (this) {
      case StockLevel.all:
        return 'تقرير مخزون العربية';
      case StockLevel.available:
        return 'تقرير الأصناف المتوفرة';
      case StockLevel.low:
        return 'تقرير الأصناف المنخفضة';
      case StockLevel.out:
        return 'تقرير الأصناف التي نفدت';
    }
  }

  String get emptyMessage {
    switch (this) {
      case StockLevel.all:
        return 'لسه مفيش أصناف محملة في العربية';
      case StockLevel.available:
        return 'لا توجد أصناف متوفرة';
      case StockLevel.low:
        return 'لا توجد أصناف منخفضة';
      case StockLevel.out:
        return 'لا توجد أصناف نفدت';
    }
  }

  String get fileTag {
    switch (this) {
      case StockLevel.all:
        return 'VehicleStockReport';
      case StockLevel.available:
        return 'VehicleStockAvailable';
      case StockLevel.low:
        return 'VehicleStockLow';
      case StockLevel.out:
        return 'VehicleStockOut';
    }
  }
}

extension VehicleStockLevelX on VehicleStockModel {
  StockLevel get level {
    if (quantity <= 0) return StockLevel.out;
    if (quantity < minThreshold) return StockLevel.low;
    return StockLevel.available;
  }
}

extension ActiveVehicleStock on List<VehicleStockModel> {
  List<VehicleStockModel> get active => where((item) {
        final product = item.product;
        return product != null && !product.isDeleted;
      }).toList();

  List<VehicleStockModel> byLevel(StockLevel level) =>
      level == StockLevel.all
          ? List<VehicleStockModel>.of(this)
          : where((item) => item.level == level).toList();

  int countOf(StockLevel level) => byLevel(level).length;
}
