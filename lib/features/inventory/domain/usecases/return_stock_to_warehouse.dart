import 'package:mivet_app/core/errors/app_exception.dart';

import '../repositories/vehicle_stock_repository.dart';

class ReturnStockToWarehouse {
  final VehicleStockRepository repository;

  const ReturnStockToWarehouse(this.repository);

  Future<void> call({
    required String vehicleId,
    required Map<String, int> quantities,
    String? note,
  }) {
    if (quantities.isEmpty) {
      throw const AppException('اختار صنف واحد على الأقل');
    }
    if (quantities.values.any((quantity) => quantity <= 0)) {
      throw const AppException('الكمية لازم تكون أكبر من صفر');
    }
    return repository.returnToWarehouse(
      vehicleId: vehicleId,
      quantities: quantities,
      note: note,
    );
  }
}
