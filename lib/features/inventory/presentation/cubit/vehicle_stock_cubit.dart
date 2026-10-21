import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/vehicle_stock_added_today_model.dart';
import '../../domain/usecases/deduct_vehicle_stock.dart';
import '../../domain/usecases/create_vehicle_for_current_rep.dart';
import '../../domain/usecases/get_stock_movements.dart';
import '../../domain/usecases/get_vehicle_stock.dart';
import '../../domain/usecases/get_vehicles.dart';
import '../../domain/usecases/load_vehicle_stock.dart';
import '../../domain/usecases/return_vehicle_stock.dart';
import '../../domain/usecases/set_vehicle_min_threshold.dart';
import '../../domain/usecases/update_vehicle_stock_quantity.dart';
import '../../domain/usecases/get_vehicle_stock_added_today_report.dart';
import 'vehicle_stock_state.dart';

class VehicleStockBatchItem {
  final String productId;
  final String productName;
  final int quantity;
  final int minThreshold;

  const VehicleStockBatchItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.minThreshold,
  });
}

class VehicleStockCubit extends Cubit<VehicleStockState> {
  final GetVehicles _getVehicles;
  final GetVehicleStock _getVehicleStock;
  final GetStockMovements _getStockMovements;
  final LoadVehicleStock _loadVehicleStock;
  final DeductVehicleStock _deductVehicleStock;
  final ReturnVehicleStock _returnVehicleStock;
  final CreateVehicleForCurrentRep _createVehicleForCurrentRep;
  final UpdateVehicleStockQuantity _updateVehicleStockQuantity;
  final SetVehicleMinThreshold _setVehicleMinThreshold;
  final GetVehicleStockAddedTodayReport _getVehicleStockAddedTodayReport;

  VehicleStockCubit({
    required GetVehicles getVehicles,
    required GetVehicleStock getVehicleStock,
    required GetStockMovements getStockMovements,
    required LoadVehicleStock loadVehicleStock,
    required DeductVehicleStock deductVehicleStock,
    required ReturnVehicleStock returnVehicleStock,
    required CreateVehicleForCurrentRep createVehicleForCurrentRep,
    required UpdateVehicleStockQuantity updateVehicleStockQuantity,
    required SetVehicleMinThreshold setVehicleMinThreshold,
    required GetVehicleStockAddedTodayReport getVehicleStockAddedTodayReport,
  })  : _getVehicles = getVehicles,
        _getVehicleStock = getVehicleStock,
        _getStockMovements = getStockMovements,
        _loadVehicleStock = loadVehicleStock,
        _deductVehicleStock = deductVehicleStock,
        _returnVehicleStock = returnVehicleStock,
        _createVehicleForCurrentRep = createVehicleForCurrentRep,
        _updateVehicleStockQuantity = updateVehicleStockQuantity,
        _setVehicleMinThreshold = setVehicleMinThreshold,
        _getVehicleStockAddedTodayReport = getVehicleStockAddedTodayReport,
        super(const VehicleStockState());

  Future<void> loadVehicles() async {
    if (isClosed) return;
    emit(state.copyWith(status: VehicleStockStatus.loading, clearError: true));
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
          errorMessage: mapErrorToAppException(e).message));
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
          errorMessage: 'أدخل رقم العربية واسم السائق'));
      return;
    }
    emit(state.copyWith(
        status: VehicleStockStatus.loadingAction,
        clearError: true,
        clearSuccess: true));
    try {
      final vehicle = await _createVehicleForCurrentRep(
          plateNumber: plate, driverName: driver);
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
          errorMessage: mapErrorToAppException(error).message));
    }
  }

  Future<void> loadSelectedVehicleData() async {
    final vehicleId = state.selectedVehicleId;
    if (vehicleId == null || isClosed) return;
    emit(state.copyWith(
        status: VehicleStockStatus.loadingStock, clearError: true));
    try {
      final vehicleStock = await _getVehicleStock(vehicleId: vehicleId);
      final movements = await _getStockMovements(vehicleId: vehicleId);
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.loaded,
          vehicleStock: vehicleStock,
          movements: movements));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.error,
          errorMessage: mapErrorToAppException(e).message));
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
        clearSuccess: true));
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
          successMessage: 'تم تحميل المخزون للعربية بنجاح'));
      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.error,
          errorMessage: mapErrorToAppException(e).message));
      rethrow;
    }
  }

  Future<List<String>> loadStockBatch({
    required String vehicleId,
    required List<VehicleStockBatchItem> items,
  }) async {
    if (isClosed || items.isEmpty) return const [];
    emit(state.copyWith(
        status: VehicleStockStatus.loadingAction,
        clearError: true,
        clearSuccess: true));
    final failed = <String>[];
    var succeeded = 0;
    for (final item in items) {
      try {
        await _loadVehicleStock(
          vehicleId: vehicleId,
          productId: item.productId,
          quantity: item.quantity,
          minThreshold: item.minThreshold,
        );
        succeeded++;
      } catch (_) {
        failed.add(item.productName);
      }
    }
    if (isClosed) return failed;
    if (succeeded > 0) {
      emit(state.copyWith(
          status: VehicleStockStatus.success,
          successMessage: succeeded == 1
              ? 'تم تحميل المخزون للعربية بنجاح'
              : 'تم تحميل $succeeded أصناف للعربية بنجاح'));
    }
    await loadSelectedVehicleData();
    return failed;
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
          errorMessage: mapErrorToAppException(e).message));
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
          errorMessage: mapErrorToAppException(e).message));
      rethrow;
    }
  }

  Future<void> updateStockQuantity({
    required String vehicleId,
    required String productId,
    required int newQuantity,
    String? note,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(
        status: VehicleStockStatus.loadingAction,
        clearError: true,
        clearSuccess: true));
    try {
      await _updateVehicleStockQuantity(
        vehicleId: vehicleId,
        productId: productId,
        newQuantity: newQuantity,
        note: note,
      );
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.success,
          successMessage: 'تم تعديل كمية المخزون بنجاح'));
      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.error,
          errorMessage: mapErrorToAppException(e).message));
      rethrow;
    }
  }

  Future<void> setMinThreshold({
    required String vehicleId,
    required String productId,
    required int minThreshold,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(
        status: VehicleStockStatus.loadingAction,
        clearError: true,
        clearSuccess: true));
    try {
      await _setVehicleMinThreshold(
        vehicleId: vehicleId,
        productId: productId,
        minThreshold: minThreshold,
      );
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.success,
          successMessage: 'تم تعديل الحد الأدنى بنجاح'));
      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          status: VehicleStockStatus.error,
          errorMessage: mapErrorToAppException(e).message));
      rethrow;
    }
  }

  Future<List<VehicleStockAddedTodayModel>> getAddedTodayReport(
    String vehicleId,
  ) async {
    return await _getVehicleStockAddedTodayReport(vehicleId);
  }

  Future<void> refresh() {
    return loadSelectedVehicleData();
  }

  void clearMessages() {
    if (isClosed) return;
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
