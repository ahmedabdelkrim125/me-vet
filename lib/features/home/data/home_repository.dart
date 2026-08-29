import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/weekly_financial_summary.dart';

class HomeRepository {
  HomeRepository(this._supabase);

  final SupabaseClient _supabase;

  WeeklyFinancialSummary? _cachedSummary;

  Future<WeeklyFinancialSummary> getWeeklyCollectionsSummary({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedSummary != null) {
      return _cachedSummary!;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(const Duration(days: 6));
    final currentWeekEnd = today.add(const Duration(days: 1));
    final previousWeekStart =
        currentWeekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = currentWeekStart;

    final rows = await _supabase
        .from('collections')
        .select('amount, collected_at')
        .gte('collected_at', previousWeekStart.toIso8601String())
        .lt('collected_at', currentWeekEnd.toIso8601String());

    double currentTotal = 0;
    double previousTotal = 0;

    for (final row in rows as List) {
      final amount = (row['amount'] as num).toDouble();
      final collectedAt = DateTime.parse(row['collected_at'] as String);

      if (!collectedAt.isBefore(currentWeekStart) &&
          collectedAt.isBefore(currentWeekEnd)) {
        currentTotal += amount;
      } else if (!collectedAt.isBefore(previousWeekStart) &&
          collectedAt.isBefore(previousWeekEnd)) {
        previousTotal += amount;
      }
    }

    final summary = WeeklyFinancialSummary(
      currentWeekCollections: currentTotal,
      previousWeekCollections: previousTotal,
    );

    _cachedSummary = summary;
    return summary;
  }

  void clearCache() {
    _cachedSummary = null;
  }
}
