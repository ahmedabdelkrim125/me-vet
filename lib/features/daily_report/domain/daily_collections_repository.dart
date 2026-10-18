import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';

class DailyCollectionSummary {
  final String code;
  final String customerName;
  final DateTime date;
  final double amount;
  final PaymentMethod? method;

  const DailyCollectionSummary({
    required this.code,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.method,
  });
}

class DailyCollectionsRepository {
  DailyCollectionsRepository._();

  static final DailyCollectionsRepository instance =
      DailyCollectionsRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<DailyCollectionSummary>> getDailyCollections({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _supabase
        .from('collections')
        .select(
          'id, code, amount, payment_method, collected_at, split_group_id, '
          'customers(name)',
        )
        .gte('collected_at', from.toUtc().toIso8601String())
        .lt('collected_at', to.toUtc().toIso8601String())
        .order('collected_at', ascending: false);

    final order = <String>[];
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final raw in rows as List<dynamic>) {
      final row = raw as Map<String, dynamic>;
      final key = (row['split_group_id'] ?? row['id']) as String;
      groups.putIfAbsent(key, () {
        order.add(key);
        return <Map<String, dynamic>>[];
      }).add(row);
    }
    return [for (final key in order) _merge(groups[key]!)];
  }

  DailyCollectionSummary _merge(List<Map<String, dynamic>> rows) {
    var total = 0.0;
    for (final row in rows) {
      total += (row['amount'] as num).toDouble();
    }
    final main = rows.reduce(
      (a, b) => _codeOf(a).length <= _codeOf(b).length ? a : b,
    );
    final customer = main['customers'] as Map<String, dynamic>?;
    return DailyCollectionSummary(
      code: _codeOf(main),
      customerName: customer?['name'] as String? ?? '',
      date: DateTime.parse(main['collected_at'] as String).toLocal(),
      amount: total,
      method: paymentMethodFromBackend(main['payment_method'] as String?),
    );
  }

  String _codeOf(Map<String, dynamic> row) => (row['code'] as String?) ?? '';
}
