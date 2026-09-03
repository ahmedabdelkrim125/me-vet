import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/auth/reauth_dialog.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/customers_repository.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import '../customers_list_view/customer_status_style.dart';
import 'edit_customer_bottom_sheet.dart';
import 'customer_schedule_sheet.dart';

class CustomerDetailHeader extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailHeader({super.key, required this.customer});

  Future<void> _editCustomer(BuildContext context) async {
    final updated =
        await showEditCustomerBottomSheet(context, customer: customer);
    if (updated == null) return;
    try {
      await CustomersRepository.instance.updateCustomer(updated);
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

  Future<void> _deleteCustomer(BuildContext context) async {
    final confirmedDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل؟'),
        content: Text(
            'هيتحذف "${customer.name}" نهائيًا. الإجراء ده مش قابل للتراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmedDelete != true || !context.mounted) return;

    final identityConfirmed =
        await confirmIdentity(context, actionLabel: 'حذف "${customer.name}"');
    if (!identityConfirmed || !context.mounted) return;

    try {
      await CustomersRepository.instance.deleteCustomer(customer.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = customerStatusColor(context, customer.status);

    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(CupertinoIcons.back,
                color: context.colors.primary, size: 22.sp),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.primary, fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${customer.code} · ${customer.category} · ${customer.area}',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.ellipsis_vertical,
                color: context.colors.textMuted, size: 20.sp),
            onSelected: (value) {
              if (value == 'edit') _editCustomer(context);
              if (value == 'delete') _deleteCustomer(context);
              if (value == 'schedule') {
                showCustomerScheduleSheet(
                  context,
                  customerId: customer.id,
                  customerName: customer.name,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit', child: Text('تعديل بيانات العميل')),
              const PopupMenuItem(
                  value: 'schedule', child: Text('مواعيد الزيارة الثابتة')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('حذف العميل', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          SizedBox(width: 4.w),
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
              _buildMenuItem(context, CustomerStatus.active, customer.status),
              _buildMenuItem(
                  context, CustomerStatus.needsFollowUp, customer.status),
              _buildMenuItem(context, CustomerStatus.stopped, customer.status),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuEntry<CustomerStatus> _buildMenuItem(
    BuildContext context,
    CustomerStatus status,
    CustomerStatus currentStatus,
  ) {
    return PopupMenuItem<CustomerStatus>(
      value: status,
      child: Row(
        children: [
          Icon(
            status == currentStatus ? CupertinoIcons.checkmark_alt : null,
            color: customerStatusColor(context, status),
          ),
          SizedBox(width: 8.w),
          Text(status.label),
        ],
      ),
    );
  }
}
