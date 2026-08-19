// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';

// import '../../../inventory/domain/models/product_model.dart';
// import '../../../inventory/domain/models/product_unit.dart';
// import '../../../inventory/domain/models/stock_alert_model.dart';

// Future<void> showRequestReloadSheet(
//   BuildContext context, {
//   required List<StockAlertModel> alerts,
//   required ProductModel? Function(String id) productResolver,
// }) {
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) =>
//         _RequestReloadSheet(alerts: alerts, productResolver: productResolver),
//   );
// }

// class _RequestReloadSheet extends StatelessWidget {
//   final List<StockAlertModel> alerts;
//   final ProductModel? Function(String id) productResolver;

//   const _RequestReloadSheet(
//       {required this.alerts, required this.productResolver});

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.6,
//       minChildSize: 0.35,
//       maxChildSize: 0.9,
//       expand: false,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: BoxDecoration(
//             color: context.colors.background,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
//           ),
//           padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Center(
//                 child: Container(
//                   width: 42.w,
//                   height: 4.h,
//                   decoration: BoxDecoration(
//                       color: context.colors.border,
//                       borderRadius: BorderRadius.circular(10.r)),
//                 ),
//               ),
//               SizedBox(height: 14.h),
//               Text('طلب إعادة تحميل العربية',
//                   style: AppTextStyles.cairoBold18
//                       .copyWith(color: context.colors.text, fontSize: 16.sp)),
//               SizedBox(height: 4.h),
//               Text(
//                 'هيتم إرسال الأصناف دي للمخزن الرئيسي عشان تحميلها',
//                 style: AppTextStyles.almaraiRegular14
//                     .copyWith(color: context.colors.textMuted, fontSize: 11.sp),
//               ),
//               SizedBox(height: 16.h),
//               Expanded(
//                 child: alerts.isEmpty
//                     ? Center(
//                         child: Text(
//                           'مفيش أصناف ناقصة دلوقتي',
//                           style: AppTextStyles.cairoMedium16.copyWith(
//                               color: context.colors.textMuted, fontSize: 13.sp),
//                         ),
//                       )
//                     : ListView.separated(
//                         controller: scrollController,
//                         itemCount: alerts.length,
//                         separatorBuilder: (_, __) => SizedBox(height: 8.h),
//                         itemBuilder: (context, index) {
//                           final alert = alerts[index];
//                           final product = productResolver(alert.productId);
//                           return Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 14.w, vertical: 12.h),
//                             decoration: BoxDecoration(
//                               color: context.colors.surface,
//                               borderRadius: BorderRadius.circular(14.r),
//                               border: Border.all(color: context.colors.border),
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(alert.productName,
//                                           style: AppTextStyles.cairoMedium16
//                                               .copyWith(
//                                                   color: context.colors.text,
//                                                   fontSize: 12.sp)),
//                                       SizedBox(height: 2.h),
//                                       Text(
//                                         'متبقي ${alert.currentQuantity} من ${alert.threshold}',
//                                         style: AppTextStyles.almaraiRegular14
//                                             .copyWith(
//                                                 color: context.colors.textMuted,
//                                                 fontSize: 10.sp),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Text(
//                                   'مقترح +${(alert.threshold * 2 - alert.currentQuantity).clamp(1, 999)} ${product?.unit.label ?? ''}',
//                                   style: AppTextStyles.cairoMedium16.copyWith(
//                                       color: context.colors.primary,
//                                       fontSize: 11.sp),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//               ),
//               SizedBox(height: 14.h),
//               Material(
//                 color: alerts.isEmpty
//                     ? context.colors.border
//                     : context.colors.primary,
//                 borderRadius: BorderRadius.circular(14.r),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(14.r),
//                   onTap: alerts.isEmpty
//                       ? null
//                       : () {
//                           Navigator.of(context).pop();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'تم إرسال طلب إعادة التحميل',
//                                 style: AppTextStyles.cairoMedium16
//                                     .copyWith(color: Colors.white),
//                               ),
//                               backgroundColor: context.colors.primary,
//                               behavior: SnackBarBehavior.floating,
//                             ),
//                           );
//                         },
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(vertical: 15.h),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(CupertinoIcons.paperplane_fill,
//                             color: Colors.white, size: 16.sp),
//                         SizedBox(width: 8.w),
//                         Text('إرسال الطلب',
//                             style: AppTextStyles.cairoMedium16.copyWith(
//                                 color: Colors.white, fontSize: 14.sp)),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/mock_inventory_repository.dart';
import '../../../inventory/domain/models/product_unit.dart';
import '../../../inventory/domain/models/stock_alert_model.dart';

Future<void> showRequestReloadSheet(BuildContext context,
    {required List<StockAlertModel> alerts}) {
  final vehicleAlerts =
      alerts.where((a) => a.level == StockAlertLevel.vehicle).toList();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RequestReloadSheet(alerts: vehicleAlerts),
  );
}

class _RequestReloadSheet extends StatefulWidget {
  final List<StockAlertModel> alerts;

  const _RequestReloadSheet({required this.alerts});

  @override
  State<_RequestReloadSheet> createState() => _RequestReloadSheetState();
}

class _RequestReloadSheetState extends State<_RequestReloadSheet> {
  bool _isProcessing = false;

  int _suggestedQuantity(StockAlertModel alert) {
    final target = alert.threshold * 2;
    final needed = target - alert.currentQuantity;
    final warehouse =
        MockInventoryRepository.instance.warehouseStockOf(alert.productId);
    final available = warehouse?.quantity ?? 0;
    return needed.clamp(1, available > 0 ? available : 1);
  }

  Future<void> _executeReload() async {
    setState(() => _isProcessing = true);

    var succeeded = 0;
    var failed = 0;

    for (final alert in widget.alerts) {
      final product =
          MockInventoryRepository.instance.productById(alert.productId);
      if (product == null) continue;

      final quantity = _suggestedQuantity(alert);
      final vehicleStock =
          MockInventoryRepository.instance.stockOf(alert.productId);
      final threshold = vehicleStock?.minThreshold ?? product.minStockThreshold;

      final error = await MockInventoryRepository.instance.loadToVehicle(
        productId: alert.productId,
        quantity: quantity,
        minThreshold: threshold,
      );

      if (error == null) {
        succeeded++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? 'تم تحميل $succeeded صنف للعربية بنجاح'
              : 'تم تحميل $succeeded صنف، وتعذر تحميل $failed (رصيد المخزن غير كافٍ)',
          style: AppTextStyles.cairoMedium16.copyWith(color: Colors.white),
        ),
        backgroundColor:
            failed == 0 ? context.colors.primary : context.colors.statOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
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
                  decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Text('طلب إعادة تحميل العربية',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.text, fontSize: 16.sp)),
              SizedBox(height: 4.h),
              Text(
                'هيتم تحميل الكميات المقترحة من المخزن الرئيسي مباشرة للعربية',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: context.colors.textMuted, fontSize: 11.sp),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: widget.alerts.isEmpty
                    ? Center(
                        child: Text(
                          'مفيش أصناف ناقصة في العربية دلوقتي',
                          style: AppTextStyles.cairoMedium16.copyWith(
                              color: context.colors.textMuted, fontSize: 13.sp),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: widget.alerts.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final alert = widget.alerts[index];
                          final product = MockInventoryRepository.instance
                              .productById(alert.productId);
                          final suggested = _suggestedQuantity(alert);
                          final warehouse = MockInventoryRepository.instance
                              .warehouseStockOf(alert.productId);
                          final available = warehouse?.quantity ?? 0;

                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: available == 0
                                    ? context.colors.statusNotReached
                                        .withOpacity(0.4)
                                    : context.colors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(alert.productName,
                                          style: AppTextStyles.cairoMedium16
                                              .copyWith(
                                                  color: context.colors.text,
                                                  fontSize: 12.sp)),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'متبقي ${alert.currentQuantity} — متاح بالمخزن $available',
                                        style: AppTextStyles.almaraiRegular14
                                            .copyWith(
                                                color: context.colors.textMuted,
                                                fontSize: 10.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  available == 0
                                      ? 'غير متاح'
                                      : 'هيتحمل +$suggested ${product?.unit.label ?? ''}',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                    color: available == 0
                                        ? context.colors.statusNotReached
                                        : context.colors.primary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 14.h),
              Material(
                color: widget.alerts.isEmpty
                    ? context.colors.border
                    : context.colors.primary,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: widget.alerts.isEmpty || _isProcessing
                      ? null
                      : _executeReload,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: _isProcessing
                        ? Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  color: Colors.white, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('تنفيذ التحميل الآن',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: Colors.white, fontSize: 14.sp)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
