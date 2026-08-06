import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import '../customers_list_view/customer_status_style.dart';

class CustomerDetailHeader extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailHeader({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = customerStatusColor(customer.status);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(CupertinoIcons.back,
                color: AppColors.primary, size: 22.sp),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: AppColors.primary, fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${customer.code} · ${customer.category} · ${customer.area}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: AppColors.navInactive, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              customer.status.label,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: color, fontSize: 10.sp),
            ),
          ),
        ],
      ),
    );
  }
}
