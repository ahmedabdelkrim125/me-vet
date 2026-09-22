import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in the platform secure storage.
///
/// Supabase swallows storage errors (it only logs a warning), so a failed
/// write silently leaves an OLD refresh token on disk and the user gets logged
/// out on the next cold start. Every operation here is therefore logged, and
/// a failed write is retried once.
class SecureLocalStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage();

  /// Last session string we know about. Only used as a fallback when the
  /// secure storage throws while the app is running.
  String? _lastKnownSession;

  SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    try {
      final value = await _storage.read(key: supabasePersistSessionKey);
      debugPrint(
        '[SecureStorage] read session: ${value == null ? 'EMPTY' : 'found'}',
      );
      if (value != null) _lastKnownSession = value;
      return value;
    } catch (e) {
      debugPrint('[SecureStorage] read FAILED: $e');
      return _lastKnownSession;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: supabasePersistSessionKey);
    } catch (e) {
      debugPrint('[SecureStorage] containsKey FAILED: $e');
      return _lastKnownSession != null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _lastKnownSession = persistSessionString;
    try {
      await _storage.write(
        key: supabasePersistSessionKey,
        value: persistSessionString,
      );
    } catch (e) {
      debugPrint('[SecureStorage] write FAILED, retrying once: $e');
      try {
        await _storage.write(
          key: supabasePersistSessionKey,
          value: persistSessionString,
        );
      } catch (e2) {
        debugPrint('[SecureStorage] write FAILED again: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<void> removePersistedSession() async {
    _lastKnownSession = null;
    try {
      await _storage.delete(key: supabasePersistSessionKey);
    } catch (e) {
      debugPrint('[SecureStorage] delete FAILED: $e');
    }
  }
}
