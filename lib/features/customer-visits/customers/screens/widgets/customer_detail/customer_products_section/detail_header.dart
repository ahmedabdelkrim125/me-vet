import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../../data/customers_repository.dart';
import '../../../../domain/models/customer_model.dart';
import '../../../../domain/models/customer_status.dart';
import '../../customers_list_view/customer_status_style.dart';
import 'status_menu_item.dart';

class CustomerDetailHeader extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailHeader({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = customerStatusColor(context, customer.status);
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: colors.primary,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.primary, fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${customer.code} · ${customer.category} · ${customer.area}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          PopupMenuButton<CustomerStatus>(
            icon: Container(
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
            onSelected: (status) async {
              try {
                await CustomersRepository.instance
                    .updateCustomerStatus(customer.id, status);
              } catch (e) {
                if (context.mounted) showAppError(context, e);
              }
            },
            itemBuilder: (context) => [
              statusMenuItem(context, CustomerStatus.active, customer.status),
              statusMenuItem(
                  context, CustomerStatus.needsFollowUp, customer.status),
              statusMenuItem(context, CustomerStatus.stopped, customer.status),
            ],
          ),
        ],
      ),
    );
  }
}
