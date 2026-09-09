import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleStockRemoteDataSource {
  final SupabaseClient _supabase;

  VehicleStockRemoteDataSource(this._supabase);

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final rows = await _supabase
        .from('vehicles')
        .select('id, plate_number, driver_name, rep_id, created_at')
        .order('plate_number', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getVehicleStock(
    String vehicleId,
  ) async {
    final rows = await _supabase
        .from('vehicle_stock')
        .select(
          'vehicle_id, product_id, quantity, min_threshold, '
          'products(id, name, image_path, category, unit, retail_price, '
          'wholesale_price, min_stock_threshold, expiry_date, created_at)',
        )
        .eq('vehicle_id', vehicleId)
        .order('product_id', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStockMovements({
    String? vehicleId,
  }) async {
    var query = _supabase.from('stock_movements').select(
          'id, product_id, vehicle_id, type, quantity, created_by, '
          'created_at, reference_id, note',
        );

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) async {
    await _supabase.rpc(
      'load_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_min_threshold': minThreshold,
        'p_note': note,
      },
    );
  }

  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    await _supabase.rpc(
      'deduct_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_reference_id': referenceId,
        'p_note': note,
      },
    );
  }

  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    await _supabase.rpc(
      'return_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_reference_id': referenceId,
        'p_note': note,
      },
    );
  }
}
