import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// استثناء موحّد بيحمل رسالة عربية جاهزة للعرض للمستخدم.
///
/// أي كود بيتعامل مباشرة مع Supabase (auth أو database أو edge functions)
/// المفروض يلف النداء بتاعه بـ try/catch وينادي [mapErrorToAppException]
/// على أي خطأ يمسكه، بدل ما يسيب الخطأ الخام (إنجليزي وتقني، أو حتى crash)
/// يوصل للمستخدم العادي.
class AppException implements Exception {
  /// الرسالة العربية اللي المفروض تتعرض للمستخدم.
  final String message;

  /// الخطأ الأصلي (للـ logs/debugging بس — مش بيتعرض للمستخدم).
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// بيحوّل أي error (من Supabase أو الشبكة أو أي حاجة تانية) لـ [AppException]
/// برسالة عربية واضحة حسب نوع الخطأ.
AppException mapErrorToAppException(Object error) {
  if (error is AppException) return error;

  final AppException mapped = switch (error) {
    AuthException() => _mapAuthException(error),
    PostgrestException() => _mapPostgrestException(error),
    FunctionException() => _mapFunctionException(error),
    SocketException() => const AppException(
        'مفيش اتصال بالإنترنت، اتأكد من الشبكة وحاول تاني'),
    TimeoutException() =>
      const AppException('الاتصال بالسيرفر بطيء، حاول تاني بعد شوية'),
    _ => AppException('حصل خطأ غير متوقع، حاول تاني', cause: error),
  };

  // بنسجّل الخطأ الأصلي في الـ console للمطوّر، بس مش بيوصل للمستخدم.
  if (kDebugMode && mapped.cause != null) {
    debugPrint('[AppException] ${mapped.cause}');
  }

  return mapped;
}

AppException _mapAuthException(AuthException error) {
  final message = error.message.toLowerCase();

  if (message.contains('invalid login credentials') ||
      message.contains('invalid_credentials')) {
    return const AppException('رقم الموبايل أو الـ PIN غلط');
  }
  if (message.contains('email not confirmed')) {
    return const AppException('الحساب ده لسه مش مفعّل، كلّم الأونر');
  }
  if (message.contains('user not found')) {
    return const AppException('مفيش حساب بالبيانات دي');
  }
  if (message.contains('rate limit') ||
      message.contains('too many requests')) {
    return const AppException('محاولات كتير قوي، استنى شوية وحاول تاني');
  }

  return AppException('فشل تسجيل الدخول، حاول تاني', cause: error);
}

AppException _mapPostgrestException(PostgrestException error) {
  switch (error.code) {
    case '23505': // unique_violation
      return const AppException(
          'البيانات دي موجودة بالفعل (رقم الموبايل أو الكود مكرر)');
    case '23503': // foreign_key_violation
      return const AppException(
          'في بيانات مرتبطة بالسجل ده، مينفعش تتعدل أو تتمسح دلوقتي');
    case '23502': // not_null_violation
      return const AppException(
          'في بيانات ناقصة، اتأكد إنك ملّيت كل الحقول المطلوبة');
    case '42501': // insufficient_privilege (RLS رفضت العملية)
      return const AppException('مفيش صلاحية إنك تعمل الحاجة دي');
    case 'PGRST116': // مفيش صف مطابق (single() مالقاش نتيجة)
      return const AppException('البيانات دي مش موجودة أو اتمسحت');
    default:
      return AppException('حصل خطأ في حفظ البيانات، حاول تاني', cause: error);
  }
}

AppException _mapFunctionException(FunctionException error) {
  final details = error.details;
  if (details is Map && details['error'] != null) {
    return AppException(details['error'].toString(), cause: error);
  }
  return AppException('حصل خطأ، حاول تاني', cause: error);
}
