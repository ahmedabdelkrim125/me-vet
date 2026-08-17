import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/models/stock_movement_model.dart';
import '../../../inventory/domain/models/stock_movement_type.dart';

Future<void> showStockMovementLogSheet(BuildContext context, List<StockMovementModel> movements) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _StockMovementLogSheet(movements: movements),
  );
}

class _StockMovementLogSheet extends StatelessWidget {
  final List<StockMovementModel> movements;

  const _StockMovementLogSheet({required this.movements});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Text('سجل حركة المخزون', style: AppTextStyles.cairoBold18.copyWith(color: context.colors.text, fontSize: 16.sp)),
              SizedBox(height: 4.h),
              Text(
                'كل عملية تحميل أو إضافة موثقة بتاريخها ووقتها',
                style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 11.sp),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: movements.isEmpty
                    ? Center(
                        child: Text(
                          'مفيش حركة مسجلة لسه',
                          style: AppTextStyles.cairoMedium16.copyWith(color: context.colors.textMuted, fontSize: 13.sp),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: movements.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) => _MovementRow(movement: movements[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MovementRow extends StatelessWidget {
  final StockMovementModel movement;

  const _MovementRow({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isLoad = movement.type == StockMovementType.loadedToVehicle;
    final color = isLoad ? context.colors.primary : context.colors.statBlue;
    final icon = isLoad ? Icons.local_shipping_outlined : Icons.warehouse_outlined;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11.r)),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.productName, style: AppTextStyles.cairoMedium16.copyWith(color: context.colors.text, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(
                  '${movement.type.label} — ${DateFormat('yyyy/MM/dd hh:mm a').format(movement.createdAt)}',
                  style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          Text('+${movement.quantity}', style: AppTextStyles.cairoBold18.copyWith(color: color, fontSize: 13.sp)),
        ],
      ),
    );
  }
}