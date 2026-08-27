import 'package:flutter/material.dart';

import '../theme/app_color_scheme_extension.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive_extension.dart';
import 'app_exception.dart';

/// يعرض رسالة خطأ بشكل موحّد (نفس الشكل والألوان) في أي شاشة في التطبيق.
///
/// بيقبل أي error خام زي ما هو — مش لازم تحوّله بنفسك، الدالة بتنادي
/// [mapErrorToAppException] تلقائيًا وتطلّع الرسالة العربية المناسبة.
///
/// الاستخدام:
/// ```dart
/// try {
///   await CustomersRepository.instance.addCustomer(customer);
/// } catch (e) {
///   if (context.mounted) showAppError(context, e);
/// }
/// ```
void showAppError(BuildContext context, Object error) {
  final appException = mapErrorToAppException(error);
  final colors = context.colors;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.statusNotReached,
        behavior: SnackBarBehavior.floating,
        content: Text(
          appException.message,
          textAlign: TextAlign.right,
          style: AppTextStyles.cairoMedium16
              .copyWith(color: Colors.white, fontSize: 13.sp),
        ),
      ),
    );
}
