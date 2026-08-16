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
  final String code;
  final DateTime date;
  final double amount;
  final InvoiceStatus status;

  const InvoiceRecordModel({
    required this.code,
    required this.date,
    required this.amount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'date': date.toIso8601String(),
        'amount': amount,
        'status': status.name,
      };

  factory InvoiceRecordModel.fromJson(Map<String, dynamic> json) {
    return InvoiceRecordModel(
      code: json['code'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => InvoiceStatus.deferred,
      ),
    );
  }
}
