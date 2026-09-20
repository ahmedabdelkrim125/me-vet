import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../../features/customer-visits/customers/data/customers_repository.dart';
import '../../features/customer-visits/customers/screens/customer_detail_screen.dart';
import '../../features/inventory/data/products_repository.dart';
import '../../features/inventory/domain/models/product_catalog.dart';
import '../../features/inventory/domain/models/product_model.dart';
import '../../features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import '../../features/inventory/presentation/widgets/product_detail_sheet.dart';
import '../../features/notification/domain/models/notification_type.dart';
import '../routing/routes.dart';

class NotificationNavigator {
  NotificationNavigator._();

  static final instance = NotificationNavigator._();

  static const int _vehicleStockTabIndex = 2;

  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, dynamic>? _pendingPayload;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setPendingPayload(Map<String, dynamic> payload) {
    _pendingPayload = payload;
  }

  Future<void> consumePending() async {
    if (_pendingPayload == null) return;

    final key = _navigatorKey;
    if (key == null) return;

    if (key.currentContext != null && key.currentContext!.mounted) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      await navigate(payload, context: key.currentContext!);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_pendingPayload == null) return;
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final payload = _pendingPayload!;
      _pendingPayload = null;
      await navigate(payload, context: ctx);
    });
  }

  Future<void> navigate(
    Map<String, dynamic> payload, {
    BuildContext? context,
  }) async {
    final typeStr = payload['type']?.toString();
    final relatedId = payload['related_id']?.toString();

    if (typeStr == null || typeStr.isEmpty) {
      debugPrint('[NotificationNavigator] type is null or empty');
      return;
    }

    final type = notificationTypeFromDb(typeStr);

    final targetContext = context ?? _navigatorKey?.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      debugPrint('[NotificationNavigator] no valid context available');
      return;
    }

    switch (type) {
      case NotificationType.visitReminder:
      case NotificationType.customerStalled:
      case NotificationType.customerDebt:
      case NotificationType.creditLimitWarning:
      case NotificationType.creditLimitExceeded:
        await _navigateToCustomer(targetContext, relatedId);
        break;

      case NotificationType.mainStockLow:
      case NotificationType.productExpiringSoon:
      case NotificationType.productExpired:
        await _navigateToProduct(targetContext, relatedId);
        break;

      case NotificationType.vehicleStockLow:
        await _navigateToVehicleStock(targetContext, relatedId);
        break;

      case NotificationType.dailyReportReminder:
        debugPrint(
            '[NotificationNavigator] dailyReportReminder: no navigation');
        break;

      case NotificationType.unknown:
        debugPrint(
            '[NotificationNavigator] unknown notification type: no navigation');
        break;
    }
  }

  Future<void> _navigateToCustomer(
    BuildContext context,
    String? customerId,
  ) async {
    if (customerId == null || customerId.isEmpty) {
      debugPrint('[NotificationNavigator] customerId is null or empty');
      return;
    }

    final customer =
        await CustomersRepository.instance.fetchCustomerById(customerId);
    if (customer == null) {
      debugPrint('[NotificationNavigator] customer not found: $customerId');
      return;
    }

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  Future<void> _navigateToProduct(
    BuildContext context,
    String? productId,
  ) async {
    if (productId == null || productId.isEmpty) {
      debugPrint('[NotificationNavigator] productId is null or empty');
      return;
    }

    ProductModel? product;
    try {
      product = await ProductsRepository.instance.getProductById(productId);
    } catch (e) {
      debugPrint('[NotificationNavigator] getProductById error: $e');
      return;
    }

    if (product == null) {
      debugPrint('[NotificationNavigator] product not found: $productId');
      return;
    }

    if (!context.mounted) return;

    ProductCatalog catalog = ProductCatalog.empty;
    try {
      final results = await Future.wait([
        ProductsRepository.instance.getCategories(),
      ]);
    } catch (e) {
      debugPrint('[NotificationNavigator] catalog load error: $e');
    }

    if (!context.mounted) return;

    await showProductDetailSheet(context, product, catalog: catalog);
  }

  Future<void> _navigateToVehicleStock(
    BuildContext context,
    String? relatedId,
  ) async {
    if (relatedId == null || relatedId.isEmpty) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: relatedId is null');
      return;
    }

    final parts = relatedId.split(':');
    if (parts.length != 2) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: malformed relatedId: $relatedId');
      return;
    }

    final vehicleId = parts[0];
    final productId = parts[1];

    if (vehicleId.isEmpty || productId.isEmpty) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low: empty vehicleId or productId');
      return;
    }

    if (!context.mounted) return;

    try {
      final cubit = sl<VehicleStockCubit>();
      await cubit.loadVehicles();

      final vehicleExists = cubit.state.vehicles.any((v) => v.id == vehicleId);
      if (!vehicleExists) {
        debugPrint(
            '[NotificationNavigator] vehicle_stock_low: vehicle not found: $vehicleId');
        return;
      }

      cubit.selectVehicle(vehicleId);

      if (!context.mounted) return;

      await Navigator.of(context).pushNamed(
        Routes.mainScreen,
        arguments: _vehicleStockTabIndex,
      );
    } catch (e) {
      debugPrint(
          '[NotificationNavigator] vehicle_stock_low navigation error: $e');
    }
  }
}
