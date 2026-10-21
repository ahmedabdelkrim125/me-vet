import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorReporter {
  ErrorReporter._();

  static Future<void> report(Object error, [StackTrace? stackTrace]) async {
    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (_) {}
  }

  static Future<void> setUser(String? id) async {
    try {
      await Sentry.configureScope(
        (scope) => scope.setUser(id == null ? null : SentryUser(id: id)),
      );
    } catch (_) {}
  }
}
