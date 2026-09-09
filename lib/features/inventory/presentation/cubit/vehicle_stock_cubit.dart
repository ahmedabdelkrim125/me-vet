import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_movement_model.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
import 'package:mivet_app/features/inventory/domain/usecases/deduct_vehicle_stock.dart';
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

  VehicleStockCubit({
    required GetVehicles getVehicles,
    required GetVehicleStock getVehicleStock,
    required GetStockMovements getStockMovements,
    required LoadVehicleStock loadVehicleStock,
    required DeductVehicleStock deductVehicleStock,
    required ReturnVehicleStock returnVehicleStock,
  })  : _getVehicles = getVehicles,
        _getVehicleStock = getVehicleStock,
        _getStockMovements = getStockMovements,
        _loadVehicleStock = loadVehicleStock,
        _deductVehicleStock = deductVehicleStock,
        _returnVehicleStock = returnVehicleStock,
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
