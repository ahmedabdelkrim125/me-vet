import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/product_picker_state.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_step_button.dart';

class ProductPickerRow extends StatelessWidget {
  final InvoiceProductModel product;
  final ProductPickerState state;

  const ProductPickerRow({
    super.key,
    required this.product,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<ProductPickerCubit>();
    final p = product;
    final qty = state.quantityFor(p);
    final available = state.availableStockFor(p);
    final outOfStock = available <= 0 && qty == 0;
    final previous = state.previousPriceFor(p);
    final price = previous ?? p.price;
    final differsFromList =
        previous != null && (previous - p.price).abs() > 0.005;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: qty > 0 ? colors.primary.withOpacity(0.08) : colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                qty > 0 ? colors.primary.withOpacity(0.35) : Colors.transparent,
          ),
        ),
        child: Opacity(
          opacity: outOfStock ? 0.5 : 1,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.text, fontSize: 12.5.sp),
                    ),
                    SizedBox(height: 4.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 2.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: (previous != null
                                    ? colors.primary
                                    : colors.textMuted)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${previous != null ? 'سعر العميل' : 'سعر البيع'}: ${formatMoney(price)}',
                            style: AppTextStyles.cairoMedium16.copyWith(
                              color: previous != null
                                  ? colors.primary
                                  : colors.text,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ),
                        if (differsFromList)
                          Text(
                            'العادي: ${formatMoney(p.price)}',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.textMuted,
                              fontSize: 10.5.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      outOfStock
                          ? 'غير متاح في مخزون العربية'
                          : 'المتاح بالعربية: $available',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: outOfStock
                            ? colors.statusNotReached
                            : colors.textMuted,
                        fontSize: 10.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (outOfStock)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text('غير متاح',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.textMuted, fontSize: 11.sp)),
                )
              else if (qty == 0)
                Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => cubit.setQuantity(p, 1),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Text('إضافة',
                          style: AppTextStyles.cairoMedium16
                              .copyWith(color: Colors.white, fontSize: 11.sp)),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    InvoiceStepButton(
                        icon: Icons.remove_rounded,
                        onTap: () => cubit.setQuantity(p, qty - 1)),
                    Container(
                      width: 28.w,
                      alignment: Alignment.center,
                      child: Text('$qty',
                          style: AppTextStyles.cairoMedium16
                              .copyWith(color: colors.text, fontSize: 12.sp)),
                    ),
                    InvoiceStepButton(
                      icon: Icons.add_rounded,
                      onTap: qty >= available
                          ? cubit.notifyStockLimit
                          : () => cubit.setQuantity(p, qty + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
