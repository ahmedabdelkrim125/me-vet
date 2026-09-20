import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/representative_report_model.dart';

class DailyReportRepository {
  final SupabaseClient _supabase;

  DailyReportRepository(this._supabase);

  Future<RepresentativeReportModel> getDailyReport({
    required DateTime from,
    required DateTime to,
    String? repId,
  }) async {
    final params = <String, dynamic>{
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
    };

    if (repId != null && repId.trim().isNotEmpty) {
      params['p_rep_id'] = repId.trim();
    }

    final response = await _supabase.rpc(
      'get_daily_report',
      params: params,
    );

    // --- STEP 1: LOG RPC PARAMS & RESPONSE ---
    debugPrint('\n=== DAILY_REPORT_DEBUG_RPC ===');
    debugPrint('FROM: ${params['p_from']}');
    debugPrint('TO: ${params['p_to']}');
    debugPrint('REP_ID: ${params['p_rep_id']}');
    debugPrint('RESPONSE: $response');

    // --- STEP 4: VERIFY ACTUAL EXPENSE IN DB ---
    try {
      final latestExpense = await _supabase
          .from('rep_expenses')
          .select('id, rep_id, amount, payment_method, category, expense_at')
          .order('expense_at', ascending: false)
          .limit(1);
      debugPrint('LATEST_EXPENSE_DB: $latestExpense');
    } catch (e) {
      debugPrint('LATEST_EXPENSE_DB_ERROR: $e');
    }
    debugPrint('==============================\n');

    final report =
        RepresentativeReportModel.fromJson(response as Map<String, dynamic>);

    return report;
  }
}
