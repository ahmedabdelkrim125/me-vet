import '../repositories/vehicle_stock_repository.dart';

class UpdateVehicleStockQuantity {
  final VehicleStockRepository repository;

  const UpdateVehicleStockQuantity(this.repository);

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int newQuantity,
    String? note,
  }) {
    return repository.updateVehicleStockQuantity(
      vehicleId: vehicleId,
      productId: productId,
      newQuantity: newQuantity,
      note: note,
    );
  }
}