import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/stock_adjustment_model.dart';

class MockStockAdjustmentsRepository {
  MockStockAdjustmentsRepository._();

  static final MockStockAdjustmentsRepository instance =
      MockStockAdjustmentsRepository._();

  static const _storageKey = 'inventory_stock_adjustments';

  final ValueNotifier<List<StockAdjustmentModel>> adjustmentsNotifier =
      ValueNotifier<List<StockAdjustmentModel>>([]);

  bool _initialized = false;

  List<StockAdjustmentModel> get adjustments => adjustmentsNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    adjustmentsNotifier.value = raw
        .map((e) => StockAdjustmentModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>))
        .toList();
    _initialized = true;
  }

  Future<void> recordReturn({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    String? note,
  }) =>
      _record(StockAdjustmentType.returned, productId, productName, quantity,
          unitPrice, note);

  Future<void> recordDamage({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    String? note,
  }) =>
      _record(StockAdjustmentType.damaged, productId, productName, quantity,
          unitPrice, note);

  Future<void> _record(
    StockAdjustmentType type,
    String productId,
    String productName,
    int quantity,
    double unitPrice,
    String? note,
  ) async {
    await initialize();
    final entry = StockAdjustmentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantity,
      value: quantity * unitPrice,
      createdAt: DateTime.now(),
      note: note,
    );
    adjustmentsNotifier.value = [entry, ...adjustments];
    await _persist();
  }

  List<StockAdjustmentModel> inRange(
    DateTime start,
    DateTime end, {
    StockAdjustmentType? type,
  }) {
    return adjustments.where((a) {
      final matchesType = type == null || a.type == type;
      return matchesType &&
          !a.createdAt.isBefore(start) &&
          a.createdAt.isBefore(end);
    }).toList();
  }

  double totalValueInRange(
      DateTime start, DateTime end, StockAdjustmentType type) {
    return inRange(start, end, type: type).fold(0.0, (sum, a) => sum + a.value);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      adjustments.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
