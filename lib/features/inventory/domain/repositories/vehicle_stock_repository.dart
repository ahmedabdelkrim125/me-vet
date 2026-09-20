// import '../models/delivery_vehicle_model.dart';
// import '../models/stock_movement_model.dart';
// import '../models/vehicle_stock_model.dart';

// abstract class VehicleStockRepository {
//   Future<List<DeliveryVehicleModel>> getVehicles();

//   Future<DeliveryVehicleModel> createVehicleForCurrentRep({
//     required String plateNumber,
//     required String driverName,
//   });

//   Future<List<VehicleStockModel>> getVehicleStock(String vehicleId);

//   Future<List<StockMovementModel>> getStockMovements({String? vehicleId});

//   Future<void> loadToVehicle({
//     required String vehicleId,
//     required String productId,
//     required int quantity,
//     required int minThreshold,
//     String? note,
//   });

//   Future<void> deductFromVehicle({
//     required String vehicleId,
//     required String productId,
//     required int quantity,
//     required String referenceId,
//     String? note,
//   });

//   Future<void> returnToVehicle({
//     required String vehicleId,
//     required String productId,
//     required int quantity,
//     required String referenceId,
//     String? note,
//   });

//   Future<void> updateVehicleStockQuantity({
//     required String vehicleId,
//     required String productId,
//     required int newQuantity,
//     String? note,
//   });
// }
import '../models/delivery_vehicle_model.dart';
import '../models/stock_movement_model.dart';
import '../models/vehicle_stock_model.dart';
import '../models/vehicle_stock_added_today_model.dart';

abstract class VehicleStockRepository {
  Future<List<DeliveryVehicleModel>> getVehicles();

  Future<DeliveryVehicleModel> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  });

  Future<List<VehicleStockModel>> getVehicleStock(String vehicleId);

  Future<List<StockMovementModel>> getStockMovements({String? vehicleId});

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

  Future<void> updateVehicleStockQuantity({
    required String vehicleId,
    required String productId,
    required int newQuantity,
    String? note,
  });

  Future<List<VehicleStockAddedTodayModel>> getVehicleStockAddedTodayShareReport(
    String vehicleId,
  );
}