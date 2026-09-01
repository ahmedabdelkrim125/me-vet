import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/models/customer_detail_model.dart';

String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

final _skeletonProducts = [
  ProductPurchaseModel(
      name: 'منتج تجريبي', price: 100, lastPurchaseDate: DateTime.now()),
  ProductPurchaseModel(
      name: 'منتج تجريبي تاني', price: 100, lastPurchaseDate: DateTime.now()),
];

class CustomerTopProductsSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;
  final bool isLoading;

  const CustomerTopProductsSection({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = isLoading ? _skeletonProducts : products;
    return _SectionCard(
      title: 'أكتر المنتجات شراءً',
      icon: CupertinoIcons.star_fill,
      iconColor: context.colors.primary,
      child: (!isLoading && products.isEmpty)
          ? const _EmptySectionMessage(text: 'لسه مفيش فواتير مسجلة للعميل ده')
          : Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: [
                  for (final product in shown)
                    _ProductRow(
                      name: product.name,
                      trailing: '${product.price.toStringAsFixed(0)} ج.م',
                      subtitle:
                          'آخر شراء ${_formatDate(product.lastPurchaseDate)}',
                    ),
                ],
              ),
            ),
    );
  }
}

class CustomerNotBoughtSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;
  final bool isLoading;

  const CustomerNotBoughtSection({
    super.key,
    required this.products,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = isLoading ? _skeletonProducts : products;
    return _SectionCard(
      title: 'منتجات لم يشترها من فترة',
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconColor: context.colors.statOrange,
      child: (!isLoading && products.isEmpty)
          ? const _EmptySectionMessage(
              text: 'مفيش منتجات بطّل يشتريها من فترة')
          : Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: [
                  for (final product in shown)
                    _ProductRow(
                      name: product.name,
                      trailing: '${product.price.toStringAsFixed(0)} ج.م',
                      subtitle:
                          'آخر شراء ${_formatDate(product.lastPurchaseDate)}',
                      showAddButton: true,
                    ),
                ],
              ),
            ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  final String text;

  const _EmptySectionMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.almaraiRegular14.copyWith(
        color: context.colors.textMuted,
        fontSize: 11.sp,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(title,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String trailing;
  final bool showAddButton;

  const _ProductRow({
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp)),
              ],
            ),
          ),
          Text(trailing,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 11.sp)),
          if (showAddButton) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(CupertinoIcons.add,
                    size: 14.sp, color: colors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
