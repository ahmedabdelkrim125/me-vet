import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/user_profile.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = Supabase.instance.client;

  /// تحويل رقم الموبايل لإيميل صناعي (Supabase Auth يعتمد على email)
  String _phoneToEmail(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleaned@mivet.app';
  }

  /// تسجيل الدخول برقم الموبايل + PIN (للمندوبين)
  Future<UserProfile?> signInWithPhone(String phone, String pin) async {
    try {
      final email = _phoneToEmail(phone);
      
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: pin,
      );

      if (authResponse.user == null) return null;

      // جلب بيانات المستخدم من جدول profiles
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      // تحديث آخر تسجيل دخول
      await _client.from('profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', profile.id);

      return profile;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  /// تسجيل الدخول بالإيميل + Password (للأونر)
  Future<UserProfile?> signInWithEmail(String email, String password) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) return null;

      // جلب بيانات المستخدم من جدول profiles
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      // التأكد أن المستخدم owner
      if (profile.role != UserRole.owner) {
        await signOut();
        throw Exception('هذا الحساب ليس حساب مدير');
      }

      // تحديث آخر تسجيل دخول
      await _client.from('profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', profile.id);

      return profile;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  /// الحصول على المستخدم الحالي
  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(profileData);
    } catch (e) {
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Stream للاستماع لحالة تسجيل الدخول
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      if (data.session == null) return null;
      return await getCurrentUser();
    });
  }

  /// التحقق من وجود session نشطة
  bool get hasActiveSession => _client.auth.currentSession != null;
}
