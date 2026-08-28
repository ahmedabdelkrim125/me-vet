/// Inventory-side view of the report: how much value moved from the
/// main warehouse to the vehicle, how much of the vehicle's load was
/// sold, and what's left in each location — plus returns/damage.
class InventoryMovementSummaryModel {
  /// Value of stock loaded FROM the main warehouse INTO the vehicle
  /// during the period (StockMovementType.loadedToVehicle).
  final double loadedFromWarehouseValue;

  /// Value of stock added directly to the main warehouse during the
  /// period (StockMovementType.addedToWarehouse) — e.g. company resupply.
  final double addedToWarehouseValue;

  /// Value of vehicle stock consumed via issued invoices in the period.
  final double soldFromVehicleValue;

  /// Value still sitting in the vehicle at the end of the period.
  final double remainingVehicleStockValue;

  /// Value still sitting in the main warehouse at the end of the period.
  final double remainingWarehouseStockValue;

  /// المرتجعات — value of goods returned by customers.
  final double returnsValue;

  /// الهالك — value of stock written off as damaged/expired.
  final double damagedGoodsValue;

  const InventoryMovementSummaryModel({
    required this.loadedFromWarehouseValue,
    required this.addedToWarehouseValue,
    required this.soldFromVehicleValue,
    required this.remainingVehicleStockValue,
    required this.remainingWarehouseStockValue,
    required this.returnsValue,
    required this.damagedGoodsValue,
  });

  static const empty = InventoryMovementSummaryModel(
    loadedFromWarehouseValue: 0,
    addedToWarehouseValue: 0,
    soldFromVehicleValue: 0,
    remainingVehicleStockValue: 0,
    remainingWarehouseStockValue: 0,
    returnsValue: 0,
    damagedGoodsValue: 0,
  );
}
