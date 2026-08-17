enum StockMovementType { loadedToVehicle, addedToWarehouse }

extension StockMovementTypeX on StockMovementType {
  String get label {
    switch (this) {
      case StockMovementType.loadedToVehicle:
        return 'تحميل للعربية';
      case StockMovementType.addedToWarehouse:
        return 'إضافة للمخزن الرئيسي';
    }
  }
}