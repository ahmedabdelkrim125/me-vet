import '../repositories/vehicle_stock_repository.dart';

class LoadVehicleStock {
  final VehicleStockRepository repository;

  const LoadVehicleStock(this.repository);

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) {
    return repository.loadToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      minThreshold: minThreshold,
      note: note,
    );
  }
}
