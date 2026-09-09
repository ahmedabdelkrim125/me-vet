import '../models/stock_movement_model.dart';
import '../repositories/vehicle_stock_repository.dart';

class GetStockMovements {
  final VehicleStockRepository repository;

  const GetStockMovements(this.repository);

  Future<List<StockMovementModel>> call({
    String? vehicleId,
  }) {
    return repository.getStockMovements(
      vehicleId: vehicleId,
    );
  }
}
