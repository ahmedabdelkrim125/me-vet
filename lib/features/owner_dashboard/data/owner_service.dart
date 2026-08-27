import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/domain/models/user_profile.dart';

class OwnerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserProfile>> getAllReps() async {
    try {
      final rows = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'rep')
          .order('created_at');
      return (rows as List)
          .map((row) => UserProfile.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<void> createRep({
    required String name,
    required String phone,
    required String pin,
  }) async {
    try {
      await _supabase.functions.invoke(
        'manage-rep',
        body: {'action': 'create', 'name': name, 'phone': phone, 'pin': pin},
      );
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }

  Future<void> deleteRep(String repId) async {
    try {
      await _supabase.functions.invoke(
        'manage-rep',
        body: {'action': 'delete', 'repId': repId},
      );
    } catch (e) {
      throw mapErrorToAppException(e);
    }
  }
}
