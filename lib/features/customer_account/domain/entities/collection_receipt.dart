import 'payment_method.dart';

class CollectionReceipt {
  final String customerName;
  final String representativeName;
  final double amount;
  final double balanceAfterCollection;
  final PaymentMethod paymentMethod;
  final DateTime collectedAt;
  final String? notes;
  final String? collectionCode;

  const CollectionReceipt({
    required this.customerName,
    required this.representativeName,
    required this.amount,
    required this.balanceAfterCollection,
    required this.paymentMethod,
    required this.collectedAt,
    this.notes,
    this.collectionCode,
  });
}

class CollectionReceiptBuildFailure implements Exception {
  final String message;

  const CollectionReceiptBuildFailure(this.message);
}
