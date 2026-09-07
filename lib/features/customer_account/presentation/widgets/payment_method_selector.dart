import 'package:flutter/material.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? value;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 11.sp),
        ),
        SizedBox(height: 6.h),
        Row(
          children: PaymentMethod.values
              .map(
                (method) => Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                        end: method == PaymentMethod.instaPay ? 0 : 6.w),
                    child: _PaymentMethodOption(
                      method: method,
                      selected: value == method,
                      onTap: () => onChanged(method),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  String get _label {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.vodafoneCash:
        return 'فودافون كاش';
      case PaymentMethod.instaPay:
        return 'إنستا باي';
    }
  }

  Widget _icon() {
    switch (method) {
      case PaymentMethod.cash:
        return const Icon(Icons.payments_outlined);
      case PaymentMethod.vodafoneCash:
        return Image.asset(AppImages.vodafoneCash, width: 32, height: 32);
      case PaymentMethod.instaPay:
        return Image.asset(AppImages.instaPay, width: 32, height: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(0.08) : colors.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 32, height: 32, child: _icon()),
            SizedBox(height: 3.h),
            Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: color, fontSize: 9.sp),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 13.sp, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
