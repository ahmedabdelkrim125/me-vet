import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/utils/invoice_formatters.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_line_item_tile.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_pagination.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_title.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_totals_row.dart';

class InvoiceProductsSection extends StatelessWidget {
  final List<InvoiceLineItemModel> items;
  final int currentPage;
  final bool loadingCustomerPrices;
  final bool stockKnown;
  final String? stockErrorMessage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAdd;
  final void Function(InvoiceLineItemModel, double) onPriceChanged;
  final void Function(InvoiceLineItemModel, int) onQuantityChanged;
  final void Function(InvoiceLineItemModel) onRemove;
  final double subtotal;
  final TextEditingController discountController;
  final ValueChanged<String> onDiscountChanged;
  final double discountAmount;
  final double grandTotal;

  const InvoiceProductsSection({
    super.key,
    required this.items,
    required this.currentPage,
    required this.loadingCustomerPrices,
    required this.stockKnown,
    this.stockErrorMessage,
    required this.onPageChanged,
    required this.onAdd,
    required this.onPriceChanged,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.subtotal,
    required this.discountController,
    required this.onDiscountChanged,
    required this.discountAmount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InvoiceSectionTitle(
          icon: Icons.inventory_2_outlined,
          title: 'الأصناف (${items.length})',
          trailing: TextButton.icon(
            onPressed: stockKnown ? onAdd : null,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 16.sp, color: colors.primary),
            label: Text(
              'إضافة منتج',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        if (!stockKnown)
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: colors.statusNotReached.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline,
                    size: 14.sp, color: colors.statusNotReached),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    stockErrorMessage ?? 'جاري تحميل مخزون العربية...',
                    style: AppTextStyles.almaraiRegular14.copyWith(
                        color: colors.statusNotReached, fontSize: 11.sp),
                  ),
                ),
              ],
            ),
          ),
        if (items.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'لا يوجد منتجات مضافة للفاتورة حتى الآن',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
          )
        else
          ...items.skip((currentPage - 1) * 15).take(15).map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InvoiceLineItemTile(
                    item: item,
                    loadingCustomerPrices: loadingCustomerPrices,
                    onPriceChanged: (price) => onPriceChanged(item, price),
                    onQuantityChanged: (q) => onQuantityChanged(item, q),
                    onRemove: () => onRemove(item),
                  ),
                ),
              ),
        if (items.isNotEmpty) ...[
          InvoicePagination(
            itemCount: items.length,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: colors.border),
          SizedBox(height: 10.h),
          InvoiceTotalsRow(
              label: 'الإجمالي قبل الخصم', value: formatMoney(subtotal)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'قيمة الخصم',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp),
              ),
              const Spacer(),
              SizedBox(
                height: 36.h,
                width: 120.w,
                child: TextFormField(
                  controller: discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: onDiscountChanged,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          InvoiceTotalsRow(
              label: 'الخصم المطبق',
              value: '- ${formatMoney(discountAmount)}',
              muted: true),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Text(
                  'إجمالي الفاتورة',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                ),
                const Spacer(),
                Text(
                  formatMoney(grandTotal),
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.primary, fontSize: 17.sp),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
