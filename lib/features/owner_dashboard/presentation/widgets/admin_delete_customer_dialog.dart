import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../customer-visits/customers/domain/models/customer_model.dart';
import '../../data/admin_actions_service.dart';

class AdminDeleteCustomerDialog extends StatefulWidget {
  final CustomerModel customer;

  const AdminDeleteCustomerDialog({super.key, required this.customer});

  @override
  State<AdminDeleteCustomerDialog> createState() =>
      _AdminDeleteCustomerDialogState();
}

class _AdminDeleteCustomerDialogState extends State<AdminDeleteCustomerDialog> {
  final _passwordController = TextEditingController();
  final _service = AdminActionsService();

  bool _isDeleting = false;
  String? _passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteCustomer() async {
    if (_isDeleting || _passwordController.text.isEmpty) return;

    setState(() {
      _isDeleting = true;
      _passwordError = null;
    });

    try {
      final deleted = await _service.deleteCustomerPermanently(
        widget.customer.id,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (!deleted) {
        setState(() => _passwordError = 'باسورد الأدمن غير صحيح');
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: Text(
          'حذف نهائي',
          style: AppTextStyles.cairoBold18
              .copyWith(color: AppColors.statusNotReached, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هيتمسح "${widget.customer.name}" نهائيًا مع كل فواتيره وزياراته '
              'وتحصيلاته ومرتجعاته. الإجراء ده مينفعش يتراجع عنه.',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: AppColors.navInactive, fontSize: 12.5.sp),
            ),
            SizedBox(height: 14.h),
            Text(
              'اكتب باسورد الأدمن للتأكيد:',
              style: AppTextStyles.almaraiRegular14.copyWith(fontSize: 12.sp),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_isDeleting,
              onChanged: (_) => setState(() => _passwordError = null),
              decoration: InputDecoration(
                hintText: 'باسورد الأدمن',
                errorText: _passwordError,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: !_isDeleting && _passwordController.text.isNotEmpty
                ? _deleteCustomer
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusNotReached,
            ),
            child: Text(
              _isDeleting ? 'جاري الحذف...' : 'حذف نهائي',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
