import 'package:flutter/material.dart';
import 'package:mivet_app/features/daily_report/domain/models/inventory_movement_summary_model.dart';
import 'report_card.dart';

class InventorySummaryCard extends StatelessWidget {
  final InventoryMovementSummaryModel inventory;
  const InventorySummaryCard({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: 'جرد المخزون',
      icon: Icons.inventory_2_outlined,
      rows: [
        (
          'محمّل من المخزن للعربية',
          moneyLabel(inventory.loadedFromWarehouseValue)
        ),
        ('مضاف للمخزن الرئيسي', moneyLabel(inventory.addedToWarehouseValue)),
        ('مباع من العربية', moneyLabel(inventory.soldFromVehicleValue)),
        ('متبقي بالعربية', moneyLabel(inventory.remainingVehicleStockValue)),
        (
          'متبقي بالمخزن الرئيسي',
          moneyLabel(inventory.remainingWarehouseStockValue)
        ),
        ('المرتجعات', moneyLabel(inventory.returnsValue)),
        ('الهالك', moneyLabel(inventory.damagedGoodsValue)),
      ],
    );
  }
}
