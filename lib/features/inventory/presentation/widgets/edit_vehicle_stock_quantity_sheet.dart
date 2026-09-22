import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class EditVehicleStockQuantitySheet extends StatefulWidget {
  final String productName;
  final int initialQuantity;

  const EditVehicleStockQuantitySheet({
    super.key,
    required this.productName,
    required this.initialQuantity,
  });

  @override
  State<EditVehicleStockQuantitySheet> createState() =>
      _EditVehicleStockQuantitySheetState();
}

class _EditVehicleStockQuantitySheetState
    extends State<EditVehicleStockQuantitySheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment() {
    setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 0) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'تعديل كمية المنتج',
            style:
                AppTextStyles.cairoBold18.copyWith(color: context.colors.text),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            widget.productName,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: context.colors.primary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAdjustButton(
                icon: CupertinoIcons.minus,
                onTap: _decrement,
                color: context.colors.text,
              ),
              SizedBox(width: 32.w),
              SizedBox(
                width: 60.w,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.text, fontSize: 24.sp),
                ),
              ),
              SizedBox(width: 32.w),
              _buildAdjustButton(
                icon: CupertinoIcons.add,
                onTap: _increment,
                color: context.colors.primary,
              ),
            ],
          ),
          SizedBox(height: 40.h),
          FilledButton(
            onPressed: () => Navigator.pop(context, _quantity),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              'حفظ التعديل',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: Colors.white, fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: 56.w,
          height: 56.w,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24.sp),
        ),
      ),
    );
  }
}
