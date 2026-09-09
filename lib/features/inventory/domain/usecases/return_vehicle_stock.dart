import '../repositories/vehicle_stock_repository.dart';

class ReturnVehicleStock {
  final VehicleStockRepository repository;

  const ReturnVehicleStock(this.repository);

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return repository.returnToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }
}
