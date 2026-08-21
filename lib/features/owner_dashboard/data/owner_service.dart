import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/models/user_profile.dart';

class OwnerService {
  OwnerService._();
  static final OwnerService instance = OwnerService._();

  final _client = Supabase.instance.client;

  /// جلب جميع المندوبين
  Future<List<UserProfile>> getAllReps() async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('role', 'rep')
          .order('created_at', ascending: false);

      return (data as List).map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل جلب المندوبين: $e');
    }
  }

  /// إنشاء مندوب جديد (سيتم استبدالها بـ Edge Function لاحقاً)
  Future<void> createRep({
    required String name,
    required String phone,
    required String pin,
    int avatarIndex = 0,
  }) async {
    try {
      // تحويل رقم الموبايل لإيميل
      final email = '${phone.replaceAll(RegExp(r'[^\d]'), '')}@mivet.app';

      // إنشاء المستخدم في auth
      // ملاحظة: هذا يحتاج service_role key وليس آمن من التطبيق مباشرة
      // يجب استخدام Edge Function في الإنتاج
      final authResponse = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: pin,
          emailConfirm: true,
          userMetadata: {
            'name': name,
            'phone': phone,
            'role': 'rep',
            'avatar_index': avatarIndex,
          },
        ),
      );

      if (authResponse.user == null) {
        throw Exception('فشل إنشاء المستخدم');
      }
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('رقم الموبايل مسجل مسبقاً');
      }
      throw Exception('خطأ في التسجيل: ${e.message}');
    } catch (e) {
      throw Exception('فشل إنشاء المندوب: $e');
    }
  }

  /// حذف مندوب
  Future<void> deleteRep(String repId) async {
    try {
      // حذف من auth (سيحذف تلقائياً من profiles بسبب cascade)
      await _client.auth.admin.deleteUser(repId);
    } catch (e) {
      throw Exception('فشل حذف المندوب: $e');
    }
  }

  /// تعطيل/تفعيل مندوب
  Future<void> toggleRepStatus(String repId, bool isActive) async {
    try {
      await _client.from('profiles').update({
        'is_active': isActive,
      }).eq('id', repId);
    } catch (e) {
      throw Exception('فشل تحديث حالة المندوب: $e');
    }
  }
}
