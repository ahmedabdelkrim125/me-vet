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

  Future<Map<String, dynamic>> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  }) async {
    final row = await _supabase.rpc(
      'create_vehicle_for_current_rep',
      params: {
        'p_plate_number': plateNumber,
        'p_driver_name': driverName,
      },
    );
    final result = row is List ? row.single : row;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getVehicleStock(
    String vehicleId,
  ) async {
    final rows = await _supabase
        .from('vehicle_stock')
        .select(
          'vehicle_id, product_id, quantity, min_threshold, '
          'products(id, name, image_path, category, retail_price, '
          'wholesale_price, min_stock_threshold, expiry_date, created_at, deleted_at)',
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
          'created_at, reference_id, note, products(name)',
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

  Future<void> updateVehicleStockQuantity({
    required String vehicleId,
    required String productId,
    required int newQuantity,
    String? note,
  }) async {
    await _supabase.rpc(
      'update_vehicle_stock_quantity',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_new_quantity': newQuantity,
        'p_note': note,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getVehicleStockAddedTodayShareReport(
    String vehicleId,
  ) async {
    final rawResult = await _supabase.rpc(
      'get_vehicle_stock_added_today_share_report',
      params: {'p_vehicle_id': vehicleId},
    );

    final Map<String, dynamic>? report = rawResult is List
        ? (rawResult.isEmpty
            ? null
            : Map<String, dynamic>.from(rawResult.first as Map))
        : (rawResult == null
            ? null
            : Map<String, dynamic>.from(rawResult as Map));

    if (report == null) return const [];

    final categories = (report['categories'] as List?) ?? const [];
    final flattened = <Map<String, dynamic>>[];

    for (final categoryRaw in categories) {
      final category = Map<String, dynamic>.from(categoryRaw as Map);
      final categoryName = category['name'] as String? ?? '';
      final products = (category['products'] as List?) ?? const [];

      for (final productRaw in products) {
        final product = Map<String, dynamic>.from(productRaw as Map);
        flattened.add({
          'product_name': product['name'],
          'category': categoryName,
          'quantity_added': product['quantity_added'],
          'current_quantity': product['current_quantity'],
          'added_at': product['added_at'],
        });
      }
    }

    return flattened;
  }
}
