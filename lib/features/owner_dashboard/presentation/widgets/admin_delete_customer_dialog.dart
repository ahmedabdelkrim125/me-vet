import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../../customer-visits/customers/domain/models/customer_model.dart';

/// حذف العميل نهائي وما يترجعش — بيتمسح معاه كل فواتيره وزياراته
/// وتحصيلاته. بنطلب من الأونر يكتب اسم العميل بالظبط قبل ما نفعّل زرار
/// الحذف، عشان ميحصلش حذف بالغلط.
class AdminDeleteCustomerDialog extends StatefulWidget {
  final CustomerModel customer;

  const AdminDeleteCustomerDialog({super.key, required this.customer});

  @override
  State<AdminDeleteCustomerDialog> createState() =>
      _AdminDeleteCustomerDialogState();
}

class _AdminDeleteCustomerDialogState extends State<AdminDeleteCustomerDialog> {
  final _confirmController = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            'اكتب اسم العميل بالظبط للتأكيد:',
            style: AppTextStyles.almaraiRegular14.copyWith(fontSize: 12.sp),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: _confirmController,
            onChanged: (v) =>
                setState(() => _matches = v.trim() == widget.customer.name),
            decoration: InputDecoration(hintText: widget.customer.name),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusNotReached),
          child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
