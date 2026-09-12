import '../../data/datasources/vehicle_stock_remote_data_source.dart';
import '../../domain/models/delivery_vehicle_model.dart';
import '../../domain/models/stock_movement_model.dart';
import '../../domain/models/vehicle_stock_model.dart';
import '../../domain/repositories/vehicle_stock_repository.dart';

class VehicleStockRepositoryImpl implements VehicleStockRepository {
  final VehicleStockRemoteDataSource remoteDataSource;

  const VehicleStockRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<DeliveryVehicleModel>> getVehicles() async {
    final rows = await remoteDataSource.getVehicles();
    return rows.map(DeliveryVehicleModel.fromMap).toList();
  }

  @override
  Future<DeliveryVehicleModel> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  }) async {
    final row = await remoteDataSource.createVehicleForCurrentRep(
      plateNumber: plateNumber,
      driverName: driverName,
    );
    return DeliveryVehicleModel.fromMap(row);
  }

  @override
  Future<List<VehicleStockModel>> getVehicleStock(String vehicleId) async {
    final rows = await remoteDataSource.getVehicleStock(vehicleId);
    return rows.map(VehicleStockModel.fromMap).toList();
  }

  @override
  Future<List<StockMovementModel>> getStockMovements(
      {String? vehicleId}) async {
    final rows = await remoteDataSource.getStockMovements(vehicleId: vehicleId);
    return rows.map(StockMovementModel.fromMap).toList();
  }

  @override
  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) {
    return remoteDataSource.loadToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      minThreshold: minThreshold,
      note: note,
    );
  }

  @override
  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return remoteDataSource.deductFromVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }

  @override
  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return remoteDataSource.returnToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }
}
