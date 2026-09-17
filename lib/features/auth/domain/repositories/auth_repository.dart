import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> signInAsRep({
    required String phone,
    required String pin,
  });

  Future<UserProfile> signInAsOwner({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserProfile?> getCurrentUser();

  Stream<UserProfile?> get authStateChanges;
}
