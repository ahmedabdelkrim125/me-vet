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
}
