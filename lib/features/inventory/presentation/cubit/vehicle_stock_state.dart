import 'package:mivet_app/features/inventory/domain/models/delivery_vehicle_model.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_movement_model.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';

enum VehicleStockStatus {
  initial,
  loading,
  loaded,
  loadingStock,
  loadingMovements,
  loadingAction,
  success,
  error,
}

class VehicleStockState {
  final VehicleStockStatus status;
  final List<DeliveryVehicleModel> vehicles;
  final String? selectedVehicleId;
  final List<VehicleStockModel> vehicleStock;
  final List<StockMovementModel> movements;
  final String? errorMessage;
  final String? successMessage;

  const VehicleStockState({
    this.status = VehicleStockStatus.initial,
    this.vehicles = const [],
    this.selectedVehicleId,
    this.vehicleStock = const [],
    this.movements = const [],
    this.errorMessage,
    this.successMessage,
  });

  DeliveryVehicleModel? get selectedVehicle {
    if (selectedVehicleId == null) return null;

    for (final vehicle in vehicles) {
      if (vehicle.id == selectedVehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  VehicleStockState copyWith({
    VehicleStockStatus? status,
    List<DeliveryVehicleModel>? vehicles,
    String? selectedVehicleId,
    List<VehicleStockModel>? vehicleStock,
    List<StockMovementModel>? movements,
    String? errorMessage,
    String? successMessage,
    bool clearSelectedVehicle = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VehicleStockState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicleId: clearSelectedVehicle
          ? null
          : selectedVehicleId ?? this.selectedVehicleId,
      vehicleStock: vehicleStock ?? this.vehicleStock,
      movements: movements ?? this.movements,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
