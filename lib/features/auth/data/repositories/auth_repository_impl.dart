import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/utils/phone_email_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<UserProfile> signInAsRep({
    required String phone,
    required String pin,
  }) async {
    final response = await _signIn(
      email: phoneToSyntheticEmail(phone),
      password: pin,
    );
    return _profileFor(response.user!.id);
  }

  @override
  Future<UserProfile> signInAsOwner({
    required String email,
    required String password,
  }) async {
    final response = await _signIn(email: email, password: password);
    final profile = await _profileFor(response.user!.id);

    if (profile.role != UserRole.owner) {
      await _supabase.auth.signOut();
      throw const AppException('هذا الحساب ليس حساب أونر');
    }
    return profile;
  }

  Future<AuthResponse> _signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password);
      if (response.user == null) {
        throw const AppException('فشل تسجيل الدخول');
      }
      return response;
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<UserProfile> _profileFor(String userId) async {
    try {
      final row =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return UserProfile.fromJson(row);
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  @override
  Future<void> signOut() => _supabase.auth.signOut();

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await _profileFor(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        return await _profileFor(user.id);
      } catch (_) {
        return null;
      }
    });
  }
}
