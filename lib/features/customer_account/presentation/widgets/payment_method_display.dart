import 'package:flutter/material.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/payment_method.dart';

class PaymentMethodDisplay extends StatelessWidget {
  final PaymentMethod? method;

  const PaymentMethodDisplay({super.key, required this.method});

  String get _label {
    switch (method) {
      case PaymentMethod.cash:
        return 'تم بـ نقدي';
      case PaymentMethod.vodafoneCash:
        return 'تم بـ Vodafone Cash';
      case PaymentMethod.instaPay:
        return 'تم بـ InstaPay';
      case null:
        return 'طريقة الدفع: غير محدد';
    }
  }

  Widget _icon() {
    switch (method) {
      case PaymentMethod.cash:
        return const Icon(Icons.payments_outlined, size: 22);
      case null:
        return const Icon(Icons.help_outline, size: 20);
      case PaymentMethod.vodafoneCash:
        return Image.asset(AppImages.vodafoneCash, width: 22, height: 22);
      case PaymentMethod.instaPay:
        return Image.asset(AppImages.instaPay, width: 22, height: 22);
    }
  }

  Color _accentColor(AppColorScheme colors) {
    switch (method) {
      case PaymentMethod.vodafoneCash:
        return const Color(0xFFE60000);
      case PaymentMethod.instaPay:
        return const Color(0xFF6D3FC4);
      case PaymentMethod.cash:
      case null:
        return colors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = _accentColor(colors);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 22.w, height: 22.h, child: _icon()),
              SizedBox(width: 4.w),
              Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.text, fontSize: 10.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
