import 'package:flutter/material.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';

class PaymentSplitRow {
  PaymentMethod? method;
  final TextEditingController amountController = TextEditingController();

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;

  void dispose() => amountController.dispose();
}
