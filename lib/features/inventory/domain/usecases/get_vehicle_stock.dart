import '../models/vehicle_stock_model.dart';
import '../repositories/vehicle_stock_repository.dart';

class GetVehicleStock {
  final VehicleStockRepository repository;

  const GetVehicleStock(this.repository);

  Future<List<VehicleStockModel>> call({
    required String vehicleId,
  }) {
    return repository.getVehicleStock(vehicleId);
  }
}
