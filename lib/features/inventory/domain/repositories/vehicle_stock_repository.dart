import '../models/delivery_vehicle_model.dart';
import '../models/stock_movement_model.dart';
import '../models/vehicle_stock_model.dart';

abstract class VehicleStockRepository {
  Future<List<DeliveryVehicleModel>> getVehicles();

  Future<List<VehicleStockModel>> getVehicleStock(
    String vehicleId,
  );

  Future<List<StockMovementModel>> getStockMovements({
    String? vehicleId,
  });

  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  });

  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  });

  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  });
}
