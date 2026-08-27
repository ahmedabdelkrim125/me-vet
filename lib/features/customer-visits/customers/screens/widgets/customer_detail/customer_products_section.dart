import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_detail_model.dart';

String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

class CustomerTopProductsSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;

  const CustomerTopProductsSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'أكتر المنتجات شراءً',
      icon: CupertinoIcons.star_fill,
      iconColor: context.colors.primary,
      child: products.isEmpty
          ? const _EmptySectionMessage(text: 'لسه مفيش فواتير مسجلة للعميل ده')
          : Column(
              children: [
                for (final product in products)
                  _ProductRow(
                    name: product.name,
                    trailing: '${product.price.toStringAsFixed(0)} ج.م',
                    subtitle:
                        'آخر شراء ${_formatDate(product.lastPurchaseDate)}',
                  ),
              ],
            ),
    );
  }
}

class CustomerNotBoughtSection extends StatelessWidget {
  final List<ProductPurchaseModel> products;

  const CustomerNotBoughtSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'منتجات لم يشترها من فترة',
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconColor: context.colors.statOrange,
      child: products.isEmpty
          ? const _EmptySectionMessage(text: 'لسه مبكّر نحدد ده لحد ما يكون في تاريخ شراء')
          : Column(
              children: [
                for (final product in products)
                  _ProductRow(
                    name: product.name,
                    trailing: '${product.price.toStringAsFixed(0)} ج.م',
                    subtitle:
                        'آخر شراء ${_formatDate(product.lastPurchaseDate)}',
                    showAddButton: true,
                  ),
              ],
            ),
    );
  }
}

class CustomerSeasonalSuggestionsSection extends StatelessWidget {
  final List<String> suggestions;

  const CustomerSeasonalSuggestionsSection(
      {super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'اقتراحات بيع موسمية',
      icon: CupertinoIcons.lightbulb_fill,
      iconColor: colors.statBlue,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final suggestion in suggestions)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: colors.statBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                suggestion,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: colors.statBlue, fontSize: 11.sp),
              ),
            ),
        ],
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
