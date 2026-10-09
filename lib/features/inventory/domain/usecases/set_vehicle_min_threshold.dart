import '../repositories/vehicle_stock_repository.dart';

class SetVehicleMinThreshold {
  final VehicleStockRepository repository;

  const SetVehicleMinThreshold(this.repository);

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int minThreshold,
  }) {
    return repository.setVehicleMinThreshold(
      vehicleId: vehicleId,
      productId: productId,
      minThreshold: minThreshold,
    );
  }
}
