import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../../customer-visits/customers/domain/models/customer_model.dart';
import '../../data/admin_actions_service.dart';
import '../admin_historical_invoice_screen.dart';
import 'admin_add_old_debt_dialog.dart';
import 'admin_delete_customer_dialog.dart';


class AdminCustomerActionsSheet extends StatelessWidget {
  final CustomerModel customer;

  const AdminCustomerActionsSheet({super.key, required this.customer});

  Future<void> _addOldDebt(BuildContext context) async {
    Navigator.pop(context);
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AdminAddOldDebtDialog(customer: customer),
    );
    if (added == true && context.mounted) {
      showAppInfo(context, 'اتضافت المديونية القديمة لـ${customer.name}');
    }
  }

  Future<void> _issueHistoricalInvoice(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminHistoricalInvoiceScreen(customer: customer),
      ),
    );
  }

  Future<void> _deletePermanently(BuildContext context) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AdminDeleteCustomerDialog(customer: customer),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AdminActionsService().deleteCustomerPermanently(customer.id);
      if (context.mounted) {
        showAppInfo(context, 'اتمسح العميل "${customer.name}" نهائيًا');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              customer.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.cairoBold18
                  .copyWith(color: AppColors.primary, fontSize: 15.sp),
            ),
            SizedBox(height: 14.h),
            _ActionTile(
              icon: Icons.history_toggle_off_rounded,
              label: 'إضافة مديونية قديمة',
              onTap: () => _addOldDebt(context),
            ),
            _ActionTile(
              icon: Icons.receipt_long_outlined,
              label: 'فاتورة تاريخية',
              onTap: () => _issueHistoricalInvoice(context),
            ),
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              label: 'حذف العميل نهائيًا',
              color: AppColors.statusNotReached,
              onTap: () => _deletePermanently(context),
            ),
            SizedBox(height: 4.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: Row(
            children: [
              Icon(icon, color: tint, size: 22.sp),
              SizedBox(width: 12.w),
              Text(
                label,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: tint, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
