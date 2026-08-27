enum CollectionSource { newInvoicePayment, oldDebtPayment }

extension CollectionSourceDb on CollectionSource {
  /// القيمة المطابقة لـ enum `collection_source` في Supabase (snake_case).
  String get dbValue => this == CollectionSource.newInvoicePayment
      ? 'new_invoice_payment'
      : 'old_debt_payment';
}

CollectionSource collectionSourceFromDb(String? value) {
  return value == 'new_invoice_payment'
      ? CollectionSource.newInvoicePayment
      : CollectionSource.oldDebtPayment;
}

/// One cash-collection event (تحصيل), needed to bucket "collections" by
/// day/week/month — CustomerModel.currentBalance alone can't do that.
class CollectionRecordModel {
  final String customerId;
  final double amount;
  final DateTime date;
  final CollectionSource source;

  const CollectionRecordModel({
    required this.customerId,
    required this.amount,
    required this.date,
    this.source = CollectionSource.oldDebtPayment,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'amount': amount,
    'date': date.toIso8601String(),
    'source': source.name,
  };

  factory CollectionRecordModel.fromJson(Map<String, dynamic> json) {
    return CollectionRecordModel(
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      source: CollectionSource.values.firstWhere(
            (s) => s.name == json['source'],
        orElse: () => CollectionSource.oldDebtPayment,
      ),
    );
  }

  /// يبني السجل من صف جدول `collections` في Supabase.
  factory CollectionRecordModel.fromSupabaseRow(Map<String, dynamic> row) {
    return CollectionRecordModel(
      customerId: row['customer_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      date: DateTime.parse(row['collected_at'] as String),
      source: collectionSourceFromDb(row['source'] as String?),
    );
  }
}