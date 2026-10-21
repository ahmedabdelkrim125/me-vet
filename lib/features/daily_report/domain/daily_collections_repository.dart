import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';

class DailyCollectionSummary {
  final String code;
  final String customerId;
  final String customerName;
  final DateTime date;
  final double amount;
  final PaymentMethod? method;
  final List<String> invoiceCodes;
  final bool isEditDifference;

  String get invoiceLabel {
    if (invoiceCodes.isEmpty) return '';
    final codes = invoiceCodes.join('، ');
    return isEditDifference ? '$codes (فرق تعديل)' : codes;
  }

  const DailyCollectionSummary({
    required this.code,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.method,
    this.invoiceCodes = const [],
    this.isEditDifference = false,
  });
}

class DailyCollectionsRepository {
  DailyCollectionsRepository._();

  static const String _editDifferenceNote = 'تحصيل فرق تعديل مبلغ الفاتورة';

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
          'customer_id, invoice_id, '
          'customers(name), invoices(code)',
        )
        .gte('collected_at', from.toUtc().toIso8601String())
        .lt('collected_at', to.toUtc().toIso8601String())
        .order('collected_at', ascending: false);

    final list = rows as List<dynamic>;
    final differenceIds = await _editDifferenceIds([
      for (final raw in list) (raw as Map<String, dynamic>)['id'] as String,
    ]);

    final order = <String>[];
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final raw in list) {
      final row = Map<String, dynamic>.from(raw as Map<String, dynamic>);
      row['_is_difference'] = differenceIds.contains(row['id']);
      final key = (row['split_group_id'] ?? row['id']) as String;
      groups.putIfAbsent(key, () {
        order.add(key);
        return <Map<String, dynamic>>[];
      }).add(row);
    }
    return [for (final key in order) _merge(groups[key]!)];
  }

  Future<Set<String>> _editDifferenceIds(List<String> collectionIds) async {
    if (collectionIds.isEmpty) return <String>{};
    try {
      final rows = await _supabase
          .from('customer_transactions')
          .select('reference_id')
          .inFilter('reference_id', collectionIds)
          .eq('notes', _editDifferenceNote);
      return {
        for (final row in rows as List<dynamic>)
          (row as Map<String, dynamic>)['reference_id'] as String,
      };
    } catch (_) {
      return <String>{};
    }
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
    final codes = <String>[];
    for (final row in rows) {
      final invoice = row['invoices'] as Map<String, dynamic>?;
      final code = invoice?['code'] as String?;
      if (code != null && !codes.contains(code)) codes.add(code);
    }
    return DailyCollectionSummary(
      code: _codeOf(main),
      customerId: (main['customer_id'] as String?) ?? '',
      customerName: customer?['name'] as String? ?? '',
      date: DateTime.parse(main['collected_at'] as String).toLocal(),
      amount: total,
      method: paymentMethodFromBackend(main['payment_method'] as String?),
      invoiceCodes: codes,
      isEditDifference:
          rows.isNotEmpty && rows.every((r) => r['_is_difference'] == true),
    );
  }

  String _codeOf(Map<String, dynamic> row) => (row['code'] as String?) ?? '';
}
