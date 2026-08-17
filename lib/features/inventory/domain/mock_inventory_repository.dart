// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'models/delivery_vehicle_model.dart';
// import 'models/product_category.dart';
// import 'models/product_model.dart';
// import 'models/product_unit.dart';
// import 'models/stock_alert_model.dart';
// import 'models/vehicle_stock_model.dart';

// class MockInventoryRepository {
//   MockInventoryRepository._();

//   static final MockInventoryRepository instance = MockInventoryRepository._();

//   final ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
//   final ValueNotifier<List<VehicleStockModel>> vehicleStock = ValueNotifier([]);
//   final ValueNotifier<List<StockAlertModel>> alerts = ValueNotifier([]);

//   final DeliveryVehicleModel currentVehicle = const DeliveryVehicleModel(
//     id: 'V-01',
//     plateNumber: 'د ن ه 4471',
//     driverName: 'محمود سعيد',
//     repName: 'أحمد محمد',
//   );

//   static const _productsKey = 'inventory_products';
//   static const _vehicleStockKey = 'inventory_vehicle_stock';
//   bool _initialized = false;

//   Future<void> init() async {
//     if (_initialized) return;
//     _initialized = true;

//     final prefs = await SharedPreferences.getInstance();
//     final storedProducts = prefs.getString(_productsKey);
//     final storedStock = prefs.getString(_vehicleStockKey);

//     if (storedProducts != null) {
//       final decoded = jsonDecode(storedProducts) as List;
//       products.value = decoded.map(_productFromJson).toList();
//     } else {
//       products.value = _seedProducts();
//       await _persistProducts();
//     }

//     if (storedStock != null) {
//       final decoded = jsonDecode(storedStock) as List;
//       vehicleStock.value = decoded.map(_stockFromJson).toList();
//     } else {
//       vehicleStock.value = _seedStock();
//       await _persistStock();
//     }

//     _refreshAlerts();
//   }

//   Future<void> addProduct(ProductModel product) async {
//     products.value = [...products.value, product];
//     await _persistProducts();
//     _refreshAlerts();
//   }

//   Future<void> updateProduct(ProductModel product) async {
//     products.value = [
//       for (final p in products.value)
//         if (p.id == product.id) product else p,
//     ];
//     await _persistProducts();
//     _refreshAlerts();
//   }

//   Future<void> deleteProduct(String id) async {
//     products.value = products.value.where((p) => p.id != id).toList();
//     vehicleStock.value =
//         vehicleStock.value.where((s) => s.productId != id).toList();
//     await _persistProducts();
//     await _persistStock();
//     _refreshAlerts();
//   }

//   ProductModel? productById(String id) {
//     for (final p in products.value) {
//       if (p.id == id) return p;
//     }
//     return null;
//   }

//   VehicleStockModel? stockOf(String productId) {
//     for (final s in vehicleStock.value) {
//       if (s.productId == productId) return s;
//     }
//     return null;
//   }

//   Future<void> addToVehicle({
//     required String productId,
//     required int quantity,
//     required int minThreshold,
//   }) async {
//     final existing = stockOf(productId);
//     final updated = [...vehicleStock.value];

//     if (existing != null) {
//       final index = updated.indexWhere((s) => s.productId == productId);
//       updated[index] = existing.copyWith(
//         quantity: existing.quantity + quantity,
//         minThreshold: minThreshold,
//       );
//     } else {
//       updated.add(VehicleStockModel(
//         productId: productId,
//         quantity: quantity,
//         minThreshold: minThreshold,
//       ));
//     }

//     vehicleStock.value = updated;
//     await _persistStock();
//     _refreshAlerts();
//   }

//   Future<void> consumeFromVehicle(String productId, int quantity) async {
//     final existing = stockOf(productId);
//     if (existing == null) return;

//     final updated = [...vehicleStock.value];
//     final index = updated.indexWhere((s) => s.productId == productId);
//     final newQuantity =
//         (existing.quantity - quantity).clamp(0, existing.quantity);
//     updated[index] = existing.copyWith(quantity: newQuantity);

//     vehicleStock.value = updated;
//     await _persistStock();
//     _refreshAlerts();
//   }

//   void _refreshAlerts() {
//     final result = <StockAlertModel>[];

//     for (final stock in vehicleStock.value) {
//       if (stock.quantity <= stock.minThreshold) {
//         final product = productById(stock.productId);
//         if (product != null) {
//           result.add(StockAlertModel(
//             productId: product.id,
//             productName: product.name,
//             level: StockAlertLevel.vehicle,
//             currentQuantity: stock.quantity,
//             threshold: stock.minThreshold,
//           ));
//         }
//       }
//     }

//     alerts.value = result;
//   }

//   Future<void> _persistProducts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final encoded = jsonEncode(products.value.map(_productToJson).toList());
//     await prefs.setString(_productsKey, encoded);
//   }

//   Future<void> _persistStock() async {
//     final prefs = await SharedPreferences.getInstance();
//     final encoded = jsonEncode(vehicleStock.value.map(_stockToJson).toList());
//     await prefs.setString(_vehicleStockKey, encoded);
//   }

//   Map<String, dynamic> _productToJson(ProductModel p) => {
//         'id': p.id,
//         'name': p.name,
//         'imagePath': p.imagePath,
//         'category': p.category.name,
//         'unit': p.unit.name,
//         'basePrice': p.basePrice,
//         'minStockThreshold': p.minStockThreshold,
//         'createdAt': p.createdAt.toIso8601String(),
//       };

//   ProductModel _productFromJson(dynamic json) {
//     final map = json as Map<String, dynamic>;
//     return ProductModel(
//       id: map['id'] as String,
//       name: map['name'] as String,
//       imagePath: map['imagePath'] as String?,
//       category:
//           ProductCategory.values.firstWhere((c) => c.name == map['category']),
//       unit: ProductUnit.values.firstWhere((u) => u.name == map['unit']),
//       basePrice: (map['basePrice'] as num).toDouble(),
//       minStockThreshold: map['minStockThreshold'] as int,
//       createdAt: map['createdAt'] != null
//           ? DateTime.parse(map['createdAt'] as String)
//           : DateTime.now(),
//     );
//   }

//   Map<String, dynamic> _stockToJson(VehicleStockModel s) => {
//         'productId': s.productId,
//         'quantity': s.quantity,
//         'minThreshold': s.minThreshold,
//       };

//   VehicleStockModel _stockFromJson(dynamic json) {
//     final map = json as Map<String, dynamic>;
//     return VehicleStockModel(
//       productId: map['productId'] as String,
//       quantity: map['quantity'] as int,
//       minThreshold: map['minThreshold'] as int,
//     );
//   }

//   List<ProductModel> _seedProducts() {
//     final now = DateTime.now();
//     return [
//       ProductModel(
//           id: 'P-1',
//           name: 'فيتامين أ د3 إي',
//           category: ProductCategory.poultry,
//           unit: ProductUnit.bottle,
//           basePrice: 180,
//           minStockThreshold: 5,
//           createdAt: now.subtract(const Duration(days: 40))),
//       ProductModel(
//           id: 'P-2',
//           name: 'مضاد حيوي واسع المجال',
//           category: ProductCategory.largeAnimal,
//           unit: ProductUnit.vial,
//           basePrice: 320,
//           minStockThreshold: 4,
//           createdAt: now.subtract(const Duration(days: 25))),
//       ProductModel(
//           id: 'P-3',
//           name: 'لقاح نيوكاسل',
//           category: ProductCategory.poultry,
//           unit: ProductUnit.box,
//           basePrice: 850,
//           minStockThreshold: 3,
//           createdAt: now.subtract(const Duration(days: 18))),
//       ProductModel(
//           id: 'P-4',
//           name: 'محلول ترطيب وريدي',
//           category: ProductCategory.largeAnimal,
//           unit: ProductUnit.bottle,
//           basePrice: 210,
//           minStockThreshold: 6,
//           createdAt: now.subtract(const Duration(days: 10))),
//       ProductModel(
//           id: 'P-5',
//           name: 'مكمل كالسيوم',
//           category: ProductCategory.supplies,
//           unit: ProductUnit.box,
//           basePrice: 130,
//           minStockThreshold: 8,
//           createdAt: now.subtract(const Duration(days: 3))),
//     ];
//   }

//   List<VehicleStockModel> _seedStock() {
//     return const [
//       VehicleStockModel(productId: 'P-1', quantity: 12, minThreshold: 5),
//       VehicleStockModel(productId: 'P-2', quantity: 3, minThreshold: 4),
//       VehicleStockModel(productId: 'P-3', quantity: 2, minThreshold: 3),
//       VehicleStockModel(productId: 'P-4', quantity: 14, minThreshold: 6),
//       VehicleStockModel(productId: 'P-5', quantity: 20, minThreshold: 8),
//     ];
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notification/domain/models/notification_type.dart';
import '../../notification/domain/notification_repository.dart';
import 'models/delivery_vehicle_model.dart';
import 'models/main_warehouse_stock_model.dart';
import 'models/product_category.dart';
import 'models/product_model.dart';
import 'models/product_unit.dart';
import 'models/stock_alert_model.dart';
import 'models/stock_movement_model.dart';
import 'models/stock_movement_type.dart';
import 'models/vehicle_stock_model.dart';

class MockInventoryRepository {
  MockInventoryRepository._();

  static final MockInventoryRepository instance = MockInventoryRepository._();

  final ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
  final ValueNotifier<List<VehicleStockModel>> vehicleStock = ValueNotifier([]);
  final ValueNotifier<List<MainWarehouseStockModel>> mainWarehouseStock = ValueNotifier([]);
  final ValueNotifier<List<StockMovementModel>> movements = ValueNotifier([]);
  final ValueNotifier<List<StockAlertModel>> alerts = ValueNotifier([]);

  final DeliveryVehicleModel currentVehicle = const DeliveryVehicleModel(
    id: 'V-01',
    plateNumber: 'د ن ه 4471',
    driverName: 'محمود سعيد',
    repName: 'أحمد محمد',
  );

  static const _productsKey = 'inventory_products';
  static const _vehicleStockKey = 'inventory_vehicle_stock';
  static const _warehouseStockKey = 'inventory_warehouse_stock';
  static const _movementsKey = 'inventory_movements';

  final Set<String> _notifiedLowStockKeys = {};
  final Set<String> _notifiedExpiryKeys = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final storedProducts = prefs.getString(_productsKey);
    final storedVehicleStock = prefs.getString(_vehicleStockKey);
    final storedWarehouseStock = prefs.getString(_warehouseStockKey);
    final storedMovements = prefs.getString(_movementsKey);

    if (storedProducts != null) {
      final decoded = jsonDecode(storedProducts) as List;
      products.value = decoded.map(_productFromJson).toList();
    } else {
      products.value = _seedProducts();
      await _persistProducts();
    }

    if (storedVehicleStock != null) {
      final decoded = jsonDecode(storedVehicleStock) as List;
      vehicleStock.value = decoded.map(_vehicleStockFromJson).toList();
    } else {
      vehicleStock.value = _seedVehicleStock();
      await _persistVehicleStock();
    }

    if (storedWarehouseStock != null) {
      final decoded = jsonDecode(storedWarehouseStock) as List;
      mainWarehouseStock.value = decoded.map(_warehouseStockFromJson).toList();
    } else {
      mainWarehouseStock.value = _seedWarehouseStock();
      await _persistWarehouseStock();
    }

    if (storedMovements != null) {
      final decoded = jsonDecode(storedMovements) as List;
      movements.value =
          decoded.map((e) => StockMovementModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    await NotificationRepository.instance.initialize();
    _refreshAlerts();
  }

  Future<void> addProduct(ProductModel product, {int initialWarehouseQuantity = 0}) async {
    products.value = [...products.value, product];
    mainWarehouseStock.value = [
      ...mainWarehouseStock.value,
      MainWarehouseStockModel(productId: product.id, quantity: initialWarehouseQuantity),
    ];
    await _persistProducts();
    await _persistWarehouseStock();
    _refreshAlerts();
  }

  Future<void> updateProduct(ProductModel product) async {
    products.value = [
      for (final p in products.value)
        if (p.id == product.id) product else p,
    ];
    await _persistProducts();
    _refreshAlerts();
  }

  Future<void> deleteProduct(String id) async {
    products.value = products.value.where((p) => p.id != id).toList();
    vehicleStock.value = vehicleStock.value.where((s) => s.productId != id).toList();
    mainWarehouseStock.value = mainWarehouseStock.value.where((s) => s.productId != id).toList();
    await _persistProducts();
    await _persistVehicleStock();
    await _persistWarehouseStock();
    _refreshAlerts();
  }

  ProductModel? productById(String id) {
    for (final p in products.value) {
      if (p.id == id) return p;
    }
    return null;
  }

  VehicleStockModel? stockOf(String productId) {
    for (final s in vehicleStock.value) {
      if (s.productId == productId) return s;
    }
    return null;
  }

  MainWarehouseStockModel? warehouseStockOf(String productId) {
    for (final s in mainWarehouseStock.value) {
      if (s.productId == productId) return s;
    }
    return null;
  }

  Future<String?> loadToVehicle({
    required String productId,
    required int quantity,
    required int minThreshold,
  }) async {
    final product = productById(productId);
    if (product == null) return 'الصنف غير موجود';

    if (product.isExpired) {
      return 'لا يمكن تحميل صنف منتهي الصلاحية للعربية';
    }

    final warehouse = warehouseStockOf(productId);
    final availableInWarehouse = warehouse?.quantity ?? 0;

    if (quantity > availableInWarehouse) {
      return 'الكمية أكبر من رصيد المخزن الرئيسي (متاح $availableInWarehouse ${product.unit.label})';
    }

    final updatedWarehouse = [...mainWarehouseStock.value];
    final warehouseIndex = updatedWarehouse.indexWhere((s) => s.productId == productId);
    updatedWarehouse[warehouseIndex] = updatedWarehouse[warehouseIndex].copyWith(
      quantity: availableInWarehouse - quantity,
    );
    mainWarehouseStock.value = updatedWarehouse;

    final existingVehicle = stockOf(productId);
    final updatedVehicle = [...vehicleStock.value];
    if (existingVehicle != null) {
      final index = updatedVehicle.indexWhere((s) => s.productId == productId);
      updatedVehicle[index] = existingVehicle.copyWith(
        quantity: existingVehicle.quantity + quantity,
        minThreshold: minThreshold,
      );
    } else {
      updatedVehicle.add(VehicleStockModel(
        productId: productId,
        quantity: quantity,
        minThreshold: minThreshold,
      ));
    }
    vehicleStock.value = updatedVehicle;

    _recordMovement(
      productId: productId,
      productName: product.name,
      type: StockMovementType.loadedToVehicle,
      quantity: quantity,
    );

    await _persistWarehouseStock();
    await _persistVehicleStock();
    await _persistMovements();
    _refreshAlerts();
    return null;
  }

  Future<void> addToWarehouse({
    required String productId,
    required int quantity,
  }) async {
    final product = productById(productId);
    if (product == null) return;

    final existing = warehouseStockOf(productId);
    final updated = [...mainWarehouseStock.value];

    if (existing != null) {
      final index = updated.indexWhere((s) => s.productId == productId);
      updated[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      updated.add(MainWarehouseStockModel(productId: productId, quantity: quantity));
    }

    mainWarehouseStock.value = updated;

    _recordMovement(
      productId: productId,
      productName: product.name,
      type: StockMovementType.addedToWarehouse,
      quantity: quantity,
    );

    await _persistWarehouseStock();
    await _persistMovements();
    _refreshAlerts();
  }

  Future<void> consumeFromVehicle(String productId, int quantity) async {
    final existing = stockOf(productId);
    if (existing == null) return;

    final updated = [...vehicleStock.value];
    final index = updated.indexWhere((s) => s.productId == productId);
    final newQuantity = (existing.quantity - quantity).clamp(0, existing.quantity);
    updated[index] = existing.copyWith(quantity: newQuantity);

    vehicleStock.value = updated;
    await _persistVehicleStock();
    _refreshAlerts();
  }

  void _recordMovement({
    required String productId,
    required String productName,
    required StockMovementType type,
    required int quantity,
  }) {
    movements.value = [
      StockMovementModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: productId,
        productName: productName,
        type: type,
        quantity: quantity,
        createdAt: DateTime.now(),
      ),
      ...movements.value,
    ];
  }

  void _refreshAlerts() {
    final result = <StockAlertModel>[];
    final newLowStockKeys = <String>{};
    final newExpiryKeys = <String>{};

    for (final stock in vehicleStock.value) {
      if (stock.quantity <= stock.minThreshold) {
        final product = productById(stock.productId);
        if (product != null) {
          result.add(StockAlertModel(
            productId: product.id,
            productName: product.name,
            level: StockAlertLevel.vehicle,
            currentQuantity: stock.quantity,
            threshold: stock.minThreshold,
          ));
          final key = 'vehicle-${product.id}';
          newLowStockKeys.add(key);
          if (!_notifiedLowStockKeys.contains(key)) {
            NotificationRepository.instance.push(
              type: NotificationType.vehicleStockLow,
              title: 'مخزون العربية منخفض',
              message: 'صنف "${product.name}" في عربيتك قل عن الحد الأدنى (متبقي ${stock.quantity}).',
            );
          }
        }
      }
    }

    for (final stock in mainWarehouseStock.value) {
      final product = productById(stock.productId);
      if (product != null && stock.quantity <= product.minStockThreshold) {
        result.add(StockAlertModel(
          productId: product.id,
          productName: product.name,
          level: StockAlertLevel.mainWarehouse,
          currentQuantity: stock.quantity,
          threshold: product.minStockThreshold,
        ));
        final key = 'warehouse-${product.id}';
        newLowStockKeys.add(key);
        if (!_notifiedLowStockKeys.contains(key)) {
          NotificationRepository.instance.push(
            type: NotificationType.mainStockLow,
            title: 'مخزون المخزن الرئيسي منخفض',
            message: 'صنف "${product.name}" في المخزن الرئيسي قل عن الحد الأدنى (متبقي ${stock.quantity}).',
          );
        }
      }
    }

    for (final product in products.value) {
      final daysLeft = product.daysUntilExpiry;
      if (daysLeft == null) continue;

      if (daysLeft < 0) {
        final key = 'expired-${product.id}';
        newExpiryKeys.add(key);
        if (!_notifiedExpiryKeys.contains(key)) {
          NotificationRepository.instance.push(
            type: NotificationType.productExpired,
            title: 'صنف منتهي الصلاحية',
            message: 'صنف "${product.name}" انتهت صلاحيته.',
          );
        }
      } else if (daysLeft <= 30) {
        final key = 'expiring-${product.id}';
        newExpiryKeys.add(key);
        if (!_notifiedExpiryKeys.contains(key)) {
          NotificationRepository.instance.push(
            type: NotificationType.productExpiringSoon,
            title: 'صلاحية قربت تخلص',
            message: 'صنف "${product.name}" هتخلص صلاحيته خلال $daysLeft يوم.',
          );
        }
      }
    }

    _notifiedLowStockKeys
      ..clear()
      ..addAll(newLowStockKeys);
    _notifiedExpiryKeys
      ..clear()
      ..addAll(newExpiryKeys);

    alerts.value = result;
  }

  Future<void> _persistProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(products.value.map(_productToJson).toList());
    await prefs.setString(_productsKey, encoded);
  }

  Future<void> _persistVehicleStock() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(vehicleStock.value.map(_vehicleStockToJson).toList());
    await prefs.setString(_vehicleStockKey, encoded);
  }

  Future<void> _persistWarehouseStock() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(mainWarehouseStock.value.map(_warehouseStockToJson).toList());
    await prefs.setString(_warehouseStockKey, encoded);
  }

  Future<void> _persistMovements() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(movements.value.map((m) => m.toJson()).toList());
    await prefs.setString(_movementsKey, encoded);
  }

  Map<String, dynamic> _productToJson(ProductModel p) => {
        'id': p.id,
        'name': p.name,
        'imagePath': p.imagePath,
        'category': p.category.name,
        'unit': p.unit.name,
        'basePrice': p.basePrice,
        'minStockThreshold': p.minStockThreshold,
        'expiryDate': p.expiryDate?.toIso8601String(),
        'createdAt': p.createdAt.toIso8601String(),
      };

  ProductModel _productFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['imagePath'] as String?,
      category: ProductCategory.values.firstWhere((c) => c.name == map['category']),
      unit: ProductUnit.values.firstWhere((u) => u.name == map['unit']),
      basePrice: (map['basePrice'] as num).toDouble(),
      minStockThreshold: map['minStockThreshold'] as int,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate'] as String) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _vehicleStockToJson(VehicleStockModel s) => {
        'productId': s.productId,
        'quantity': s.quantity,
        'minThreshold': s.minThreshold,
      };

  VehicleStockModel _vehicleStockFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return VehicleStockModel(
      productId: map['productId'] as String,
      quantity: map['quantity'] as int,
      minThreshold: map['minThreshold'] as int,
    );
  }

  Map<String, dynamic> _warehouseStockToJson(MainWarehouseStockModel s) => {
        'productId': s.productId,
        'quantity': s.quantity,
      };

  MainWarehouseStockModel _warehouseStockFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return MainWarehouseStockModel(
      productId: map['productId'] as String,
      quantity: map['quantity'] as int,
    );
  }

  List<ProductModel> _seedProducts() {
    final now = DateTime.now();
    return [
      ProductModel(id: 'P-1', name: 'فيتامين أ د3 إي', category: ProductCategory.poultry, unit: ProductUnit.bottle, basePrice: 180, minStockThreshold: 5, expiryDate: now.add(const Duration(days: 200)), createdAt: now.subtract(const Duration(days: 40))),
      ProductModel(id: 'P-2', name: 'مضاد حيوي واسع المجال', category: ProductCategory.largeAnimal, unit: ProductUnit.vial, basePrice: 320, minStockThreshold: 4, expiryDate: now.add(const Duration(days: 20)), createdAt: now.subtract(const Duration(days: 25))),
      ProductModel(id: 'P-3', name: 'لقاح نيوكاسل', category: ProductCategory.poultry, unit: ProductUnit.box, basePrice: 850, minStockThreshold: 3, expiryDate: now.subtract(const Duration(days: 2)), createdAt: now.subtract(const Duration(days: 18))),
      ProductModel(id: 'P-4', name: 'محلول ترطيب وريدي', category: ProductCategory.largeAnimal, unit: ProductUnit.bottle, basePrice: 210, minStockThreshold: 6, createdAt: now.subtract(const Duration(days: 10))),
      ProductModel(id: 'P-5', name: 'مكمل كالسيوم', category: ProductCategory.supplies, unit: ProductUnit.box, basePrice: 130, minStockThreshold: 8, createdAt: now.subtract(const Duration(days: 3))),
    ];
  }

  List<VehicleStockModel> _seedVehicleStock() {
    return const [
      VehicleStockModel(productId: 'P-1', quantity: 12, minThreshold: 5),
      VehicleStockModel(productId: 'P-2', quantity: 3, minThreshold: 4),
      VehicleStockModel(productId: 'P-3', quantity: 2, minThreshold: 3),
      VehicleStockModel(productId: 'P-4', quantity: 14, minThreshold: 6),
      VehicleStockModel(productId: 'P-5', quantity: 20, minThreshold: 8),
    ];
  }

  List<MainWarehouseStockModel> _seedWarehouseStock() {
    return const [
      MainWarehouseStockModel(productId: 'P-1', quantity: 60),
      MainWarehouseStockModel(productId: 'P-2', quantity: 8),
      MainWarehouseStockModel(productId: 'P-3', quantity: 15),
      MainWarehouseStockModel(productId: 'P-4', quantity: 40),
      MainWarehouseStockModel(productId: 'P-5', quantity: 70),
    ];
  }
}