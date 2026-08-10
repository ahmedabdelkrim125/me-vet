import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/stock_alert_model.dart';

class LowStockAlertBanner extends StatelessWidget {
  final List<StockAlertModel> alerts;

  const LowStockAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.colors.statOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.statOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: context.colors.statOrange, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${alerts.length} صنف قل عن الحد الأدنى في عربيتك',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: context.colors.text, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          for (final alert in alerts)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '${alert.productName} — متبقي ${alert.currentQuantity} من ${alert.threshold}',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: context.colors.textMuted, fontSize: 10.sp),
              ),
            ),
        ],
      ),
    );
  }
}
