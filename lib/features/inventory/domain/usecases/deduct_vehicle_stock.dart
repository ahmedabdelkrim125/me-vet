import '../repositories/vehicle_stock_repository.dart';

class DeductVehicleStock {
  final VehicleStockRepository repository;

  const DeductVehicleStock(this.repository);

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return repository.deductFromVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }
}
