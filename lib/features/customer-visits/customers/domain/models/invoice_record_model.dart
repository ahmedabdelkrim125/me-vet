enum InvoiceStatus { paid, partial, deferred }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'مدفوعة';
      case InvoiceStatus.partial:
        return 'جزئي';
      case InvoiceStatus.deferred:
        return 'آجلة';
    }
  }
}

class InvoiceRecordModel {
  final String id;
  final String code;
  final DateTime date;
  final double amount;
  final double paidAmount;
  final InvoiceStatus status;

  const InvoiceRecordModel({
    required this.id,
    required this.code,
    required this.date,
    required this.amount,
    this.paidAmount = 0,
    required this.status,
  });

  double get remaining => amount - paidAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'date': date.toIso8601String(),
        'amount': amount,
        'paidAmount': paidAmount,
        'status': status.name,
      };

  factory InvoiceRecordModel.fromJson(Map<String, dynamic> json) {
    return InvoiceRecordModel(
      // Defensive fallback: locally cached JSON written before this field
      // existed won't have an 'id' key.
      id: json['id'] as String? ?? '',
      code: json['code'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => InvoiceStatus.deferred,
      ),
    );
  }

  factory InvoiceRecordModel.fromSupabaseRow(Map<String, dynamic> row) {
    return InvoiceRecordModel(
      id: row['id'] as String,
      code: row['code'] as String,
      date: DateTime.parse(row['invoice_date'] as String),
      amount: (row['total_amount'] as num).toDouble(),
      paidAmount: (row['paid_now'] as num?)?.toDouble() ?? 0,
      status: _statusFromDb(row['status'] as String?),
    );
  }
}

InvoiceStatus _statusFromDb(String? value) {
  switch (value) {
    case 'paid':
      return InvoiceStatus.paid;
    case 'partial':
      return InvoiceStatus.partial;
    case 'deferred':
    default:
      return InvoiceStatus.deferred;
  }
}
