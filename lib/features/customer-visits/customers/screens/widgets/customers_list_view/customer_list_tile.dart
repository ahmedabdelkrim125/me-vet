import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import '../../customer_detail_screen.dart';
import 'customer_status_style.dart';

class CustomerListTile extends StatelessWidget {
  final CustomerModel customer;

  const CustomerListTile({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = customerStatusColor(customer.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer)),
        ),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(CupertinoIcons.person_2_fill,
                    color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTextStyles.cairoMedium16.copyWith(
                        color: AppColors.primary,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${customer.category} — ${customer.area}',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: AppColors.navInactive,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<CustomerStatus>(
                icon: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
                  await MockCustomersRepository.instance
                      .updateCustomerStatus(customer.id, status);
                },
                itemBuilder: (context) => [
                  _buildMenuItem(CustomerStatus.active),
                  _buildMenuItem(CustomerStatus.needsFollowUp),
                  _buildMenuItem(CustomerStatus.stopped),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<CustomerStatus> _buildMenuItem(CustomerStatus status) {
    return PopupMenuItem<CustomerStatus>(
      value: status,
      child: Row(
        children: [
          Icon(
            status == customer.status ? CupertinoIcons.checkmark_alt : null,
            color: customerStatusColor(status),
          ),
          SizedBox(width: 8.w),
          Text(status.label),
        ],
      ),
    );
  }
}
