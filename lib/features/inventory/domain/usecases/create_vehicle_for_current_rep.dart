import '../models/delivery_vehicle_model.dart';
import '../repositories/vehicle_stock_repository.dart';

class CreateVehicleForCurrentRep {
  final VehicleStockRepository _repository;

  const CreateVehicleForCurrentRep(this._repository);

  Future<DeliveryVehicleModel> call({
    required String plateNumber,
    required String driverName,
  }) =>
      _repository.createVehicleForCurrentRep(
        plateNumber: plateNumber,
        driverName: driverName,
      );
}
