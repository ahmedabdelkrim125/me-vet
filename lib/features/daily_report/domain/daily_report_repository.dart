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

    if (response is! Map) {
      throw const FormatException('رد التقرير من السيرفر غير صالح');
    }

    dynamic returnsJson;
    try {
      returnsJson = await _supabase.rpc(
        'get_returns_report',
        params: params,
      );
    } catch (e) {
      debugPrint('[Report] تعذر تحميل تفاصيل المرتجعات: $e');
    }

    return RepresentativeReportModel.fromJson(
      Map<String, dynamic>.from(response),
      fallbackFrom: from,
      fallbackTo: to,
      returnsJson: returnsJson,
    );
  }
}
