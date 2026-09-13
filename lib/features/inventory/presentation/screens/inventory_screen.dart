import 'package:flutter/material.dart';
import 'package:mivet_app/features/vehicle_stock/presentation/screens/vehicle_stock_screen.dart';

/// Compatibility entry point for former catalog deep links. The operational
/// flow is one vehicle-stock screen, with product actions in vehicle context.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const VehicleStockScreen();
}
