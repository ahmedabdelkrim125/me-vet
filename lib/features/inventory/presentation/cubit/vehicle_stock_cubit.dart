import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_movement_model.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
import 'package:mivet_app/features/inventory/domain/usecases/deduct_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/create_vehicle_for_current_rep.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_stock_movements.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_vehicles.dart';
import 'package:mivet_app/features/inventory/domain/usecases/load_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/return_vehicle_stock.dart';

import 'vehicle_stock_state.dart';

class VehicleStockCubit extends Cubit<VehicleStockState> {
  final GetVehicles _getVehicles;
  final GetVehicleStock _getVehicleStock;
  final GetStockMovements _getStockMovements;
  final LoadVehicleStock _loadVehicleStock;
  final DeductVehicleStock _deductVehicleStock;
  final ReturnVehicleStock _returnVehicleStock;
  final CreateVehicleForCurrentRep _createVehicleForCurrentRep;

  VehicleStockCubit({
    required GetVehicles getVehicles,
    required GetVehicleStock getVehicleStock,
    required GetStockMovements getStockMovements,
    required LoadVehicleStock loadVehicleStock,
    required DeductVehicleStock deductVehicleStock,
    required ReturnVehicleStock returnVehicleStock,
    required CreateVehicleForCurrentRep createVehicleForCurrentRep,
  })  : _getVehicles = getVehicles,
        _getVehicleStock = getVehicleStock,
        _getStockMovements = getStockMovements,
        _loadVehicleStock = loadVehicleStock,
        _deductVehicleStock = deductVehicleStock,
        _returnVehicleStock = returnVehicleStock,
        _createVehicleForCurrentRep = createVehicleForCurrentRep,
        super(const VehicleStockState());

  Future<void> loadVehicles() async {
    if (isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loading,
      clearError: true,
    ));

    try {
      final vehicles = await _getVehicles();

      if (isClosed) return;

      final currentId = state.selectedVehicleId;
      final currentExists = currentId != null &&
          vehicles.any((vehicle) => vehicle.id == currentId);

      final selectedId = currentExists
          ? currentId
          : vehicles.isNotEmpty
              ? vehicles.first.id
              : null;

      if (selectedId == null) {
        emit(state.copyWith(
          status: VehicleStockStatus.loaded,
          vehicles: vehicles,
          clearSelectedVehicle: true,
          vehicleStock: const [],
          movements: const [],
        ));
        return;
      }

      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicles: vehicles,
        selectedVehicleId: selectedId,
        clearError: true,
      ));

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> selectVehicle(String vehicleId) async {
    if (isClosed) return;

    emit(state.copyWith(
      selectedVehicleId: vehicleId,
      status: VehicleStockStatus.loadingStock,
      clearError: true,
      clearSuccess: true,
      vehicleStock: const [],
      movements: const [],
    ));

    await loadSelectedVehicleData();
  }

  Future<void> createVehicle({
    required String plateNumber,
    required String driverName,
  }) async {
    final plate = plateNumber.trim();
    final driver = driverName.trim();
    if (plate.isEmpty || driver.isEmpty) {
      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: 'أدخل رقم العربية واسم السائق',
      ));
      return;
    }

    emit(state.copyWith(
      status: VehicleStockStatus.loadingAction,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final vehicle = await _createVehicleForCurrentRep(
        plateNumber: plate,
        driverName: driver,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicles: [vehicle],
        selectedVehicleId: vehicle.id,
        vehicleStock: const [],
        movements: const [],
        successMessage: 'تم إنشاء العربية بنجاح',
      ));
      await loadSelectedVehicleData();
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(error).message,
      ));
    }
  }

  Future<void> loadSelectedVehicleData() async {
    final vehicleId = state.selectedVehicleId;

    if (vehicleId == null || isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loadingStock,
      clearError: true,
    ));

    try {
      final List<VehicleStockModel> vehicleStock =
          await _getVehicleStock(vehicleId: vehicleId);

      final List<StockMovementModel> movements =
          await _getStockMovements(vehicleId: vehicleId);

      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicleStock: vehicleStock,
        movements: movements,
      ));
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> loadStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loadingAction,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _loadVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        minThreshold: minThreshold,
        note: note,
      );

      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.success,
        successMessage: 'تم تحميل المخزون للعربية بنجاح',
      ));

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
      rethrow;
    }
  }

  Future<void> deductStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    if (isClosed) return;

    try {
      await _deductVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        note: note,
      );

      if (isClosed) return;

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));

      rethrow;
    }
  }

  Future<void> returnStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    if (isClosed) return;

    try {
      await _returnVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        note: note,
      );

      if (isClosed) return;

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));

      rethrow;
    }
  }

  Future<void> refresh() {
    return loadSelectedVehicleData();
  }

  void clearMessages() {
    if (isClosed) return;

    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}
