enum CollectionSource { newInvoicePayment, oldDebtPayment }

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
}