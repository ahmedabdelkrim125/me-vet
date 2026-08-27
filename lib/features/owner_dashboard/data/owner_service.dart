import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/models/user_profile.dart';

class OwnerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserProfile>> getAllReps() async {
    final rows = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'rep')
        .order('created_at');
    return (rows as List)
        .map((row) => UserProfile.fromJson(row as Map<String, dynamic>))
        .toList();
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
    } on FunctionException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> deleteRep(String repId) async {
    try {
      await _supabase.functions.invoke(
        'manage-rep',
        body: {'action': 'delete', 'repId': repId},
      );
    } on FunctionException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return 'حصل خطأ، حاول تاني';
  }
}
