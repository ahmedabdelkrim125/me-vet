import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

abstract class ErrorMapper {
  bool canHandle(Object error);
  AppException map(Object error);
}

class AuthErrorMapper implements ErrorMapper {
  @override
  bool canHandle(Object error) => error is AuthException;

  @override
  AppException map(Object error) {
    final e = error as AuthException;
    final message = e.message.toLowerCase();

    if (message.contains('expired') ||
        message.contains('refresh token') ||
        message.contains('invalid token') ||
        message.contains('session')) {
      return AppException('انتهت جلسة الدخول، سجّل الدخول مرة أخرى',
          cause: error);
    }

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
}

class PostgrestErrorMapper implements ErrorMapper {
  @override
  bool canHandle(Object error) => error is PostgrestException;

  @override
  AppException map(Object error) {
    final e = error as PostgrestException;
    if (e.code == '401' || e.code == 'PGRST301') {
      return AppException('انتهت جلسة الدخول، سجّل الدخول مرة أخرى',
          cause: error);
    }
    switch (e.code) {
      case '23505':
        return const AppException(
            'البيانات دي موجودة بالفعل (رقم الموبايل أو الكود مكرر)');
      case '23503':
        return const AppException(
            'في بيانات مرتبطة بالسجل ده، مينفعش تتعدل أو تتمسح دلوقتي');
      case '23502':
        return const AppException(
            'في بيانات ناقصة، اتأكد إنك ملّيت كل الحقول المطلوبة');
      case '42501':
        return const AppException('مفيش صلاحية إنك تعمل الحاجة دي');
      case 'PGRST116':
        return const AppException('البيانات دي مش موجودة أو اتمسحت');
      default:
        return AppException('حصل خطأ في حفظ البيانات، حاول تاني', cause: error);
    }
  }
}

class FunctionErrorMapper implements ErrorMapper {
  @override
  bool canHandle(Object error) => error is FunctionException;

  @override
  AppException map(Object error) {
    final e = error as FunctionException;
    if (e.status == 401) {
      return AppException('انتهت جلسة الدخول، سجّل الدخول مرة أخرى',
          cause: error);
    }
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return AppException(details['error'].toString(), cause: error);
    }
    return AppException('حصل خطأ، حاول تاني', cause: error);
  }
}

class ErrorHandler {
  static final List<ErrorMapper> _mappers = [
    AuthErrorMapper(),
    PostgrestErrorMapper(),
    FunctionErrorMapper(),
  ];

  static AppException handle(Object error) {
    if (error is AppException) return error;

    for (final mapper in _mappers) {
      if (mapper.canHandle(error)) {
        return mapper.map(error);
      }
    }

    if (error is SocketException) {
      return const AppException(
          'مفيش اتصال بالإنترنت، اتأكد من الشبكة وحاول تاني');
    }
    if (error is TimeoutException) {
      return const AppException('الاتصال بالسيرفر بطيء، حاول تاني بعد شوية');
    }

    return AppException('حصل خطأ غير متوقع، حاول تاني', cause: error);
  }
}

AppException mapErrorToAppException(Object error) {
  final mapped = ErrorHandler.handle(error);

  if (kDebugMode && mapped.cause != null) {
    debugPrint('[AppException] ${mapped.cause}');
  }

  return mapped;
}
