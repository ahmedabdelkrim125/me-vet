import '../models/user_profile.dart';

abstract class AuthRepository {
  /// تسجيل دخول مندوب (phone + PIN)
  Future<UserProfile> signInAsRep({
    required String phone,
    required String pin,
  });

  /// تسجيل دخول أونر (email + password)
  Future<UserProfile> signInAsOwner({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserProfile?> getCurrentUser();

  Stream<UserProfile?> get authStateChanges;
}
