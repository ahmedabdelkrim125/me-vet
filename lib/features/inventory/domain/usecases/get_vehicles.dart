import '../models/delivery_vehicle_model.dart';
import '../repositories/vehicle_stock_repository.dart';

class GetVehicles {
  final VehicleStockRepository repository;

  const GetVehicles(this.repository);

  Future<List<DeliveryVehicleModel>> call() {
    return repository.getVehicles();
  }
}
