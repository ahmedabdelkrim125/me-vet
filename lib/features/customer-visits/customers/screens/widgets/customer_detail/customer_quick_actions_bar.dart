import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/launch_utils.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';

class CustomerQuickActionsBar extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback? onInvoiceTap;
  final VoidCallback? onCollectTap;

  const CustomerQuickActionsBar({
    super.key,
    required this.customer,
    this.onInvoiceTap,
    this.onCollectTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: _ActionItem(
            icon: CupertinoIcons.cart_fill,
            label: 'فاتورة',
            color: colors.primary,
            onTap: onInvoiceTap ?? () {},
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _ActionItem(
            icon: CupertinoIcons.money_dollar_circle_fill,
            label: 'تحصيل',
            color: colors.statBlue,
            onTap: onCollectTap ?? () {},
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _ActionItem(
            icon: CupertinoIcons.phone_fill,
            label: 'اتصال',
            color: colors.text,
            onTap: () => LaunchUtils.call(context, customer.phone),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _ActionItem(
            icon: CupertinoIcons.chat_bubble_2_fill,
            label: 'واتساب',
            color: colors.statOrange,
            onTap: () => LaunchUtils.whatsapp(
              context,
              customer.phone,
              message: 'أهلًا ${customer.name}، معاك المندوب من MIVET.',
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _ActionItem(
            icon: CupertinoIcons.location_solid,
            label: 'الموقع',
            color: colors.statusNotReached,
            onTap: () => LaunchUtils.openMap(
              context,
              customer.address.isEmpty ? customer.area : customer.address,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(height: 6.h),
              Text(label,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 10.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
