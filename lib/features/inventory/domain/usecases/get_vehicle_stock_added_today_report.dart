import '../models/vehicle_stock_added_today_model.dart';
import '../repositories/vehicle_stock_repository.dart';

class GetVehicleStockAddedTodayReport {
  final VehicleStockRepository repository;

  const GetVehicleStockAddedTodayReport(this.repository);

  Future<List<VehicleStockAddedTodayModel>> call(String vehicleId) {
    return repository.getVehicleStockAddedTodayShareReport(vehicleId);
  }
}
